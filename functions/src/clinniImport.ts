/**
 * Cloud Function `importClinniAppointments` (onCall).
 *
 * Recibe el contenido base64 de un Excel de Clinni desde el panel admin
 * (Flutter Windows), lo parsea con la librería `xlsx`, deduplica las
 * citas por hash (telefono + fechaCita ISO + profesional) y las inserta
 * en `clinni_appointments`.
 *
 * Esquema esperado del Excel (columnas, orden flexible):
 *  - "Paciente" | "Nombre" -> pacienteNombre
 *  - "Teléfono" | "Telefono" | "Móvil" | "Movil" -> pacienteTelefono
 *  - "Fecha" | "Fecha cita" + "Hora" -> fechaCita
 *  - "Profesional" | "Doctor" -> profesional
 *  - "Servicio" | "Tratamiento" -> servicio
 *  - "Notas" | "Observaciones" -> notas (opcional)
 */

import {onRequest} from "firebase-functions/v2/https";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as XLSX from "xlsx";
import {normalizePhone} from "./whatsapp";

/**
 * Verifica auth Bearer token en el header Authorization. Usado por los
 * endpoints HTTP onRequest porque el plugin cloud_functions de Flutter no
 * soporta Windows desktop oficialmente. El cliente envía el ID token de
 * Firebase Auth como `Authorization: Bearer <idToken>` y aquí lo
 * verificamos con admin.auth(). Devuelve null si no hay auth válida o si
 * el usuario no es admin/administrador (la response ya incluye el código).
 */
async function verifyAdminBearer(
    req: import("firebase-functions/v2/https").Request,
    res: import("express").Response,
): Promise<string | null> {
  const authHeader = req.headers.authorization ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    res.status(401).json({error: "Falta Authorization Bearer token"});
    return null;
  }
  const idToken = authHeader.substring("Bearer ".length).trim();
  let uid: string;
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    uid = decoded.uid;
  } catch (e) {
    functions.logger.warn("verifyIdToken falló", {error: String(e)});
    res.status(401).json({error: "Token inválido o expirado"});
    return null;
  }
  const userDoc = await admin.firestore()
      .collection("users_app").doc(uid).get();
  const rol = ((userDoc.data()?.rol as string) ?? "").toLowerCase();
  if (!["admin", "administrador"].includes(rol)) {
    res.status(403).json({error: "Solo admin puede invocar"});
    return null;
  }
  return uid;
}

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

interface ParsedRow {
  pacienteNombre: string;
  pacienteTelefono: string;
  fechaCita: Date;
  profesional: string;
  servicio: string;
  notas: string;
}

const COLUMN_ALIASES = {
  pacienteNombre: ["paciente", "nombre", "cliente"],
  pacienteTelefono: ["telefono", "teléfono", "movil", "móvil", "tel", "celular", "phone"],
  fecha: ["fecha", "fecha cita", "fecha de la cita", "fechacita", "date"],
  hora: ["hora", "hora cita", "horacita", "time"],
  fechaHora: ["fecha y hora", "fechahora", "datetime"],
  profesional: ["profesional", "doctor", "doctora", "médico", "medico", "terapeuta"],
  servicio: ["servicio", "tratamiento", "tipo", "tipo cita", "service"],
  notas: ["notas", "observaciones", "comentarios", "notes"],
};

function findColumn(
    headers: string[],
    aliases: string[],
): number {
  const normalized = headers.map((h) =>
    String(h ?? "").toLowerCase().trim().replace(/\s+/g, " "),
  );
  for (const alias of aliases) {
    const idx = normalized.indexOf(alias);
    if (idx >= 0) return idx;
  }
  return -1;
}

function parseDate(raw: unknown): Date | null {
  if (!raw) return null;
  if (raw instanceof Date) return raw;
  if (typeof raw === "number") {
    // Excel serial date (días desde 1900-01-01)
    const utcDays = Math.floor(raw - 25569);
    const utcMs = utcDays * 86400 * 1000;
    const fractional = raw - Math.floor(raw);
    return new Date(utcMs + fractional * 86400 * 1000);
  }
  if (typeof raw === "string") {
    const trimmed = raw.trim();
    if (!trimmed) return null;
    // Intentar formatos: "DD/MM/YYYY HH:mm", "YYYY-MM-DD HH:mm", ISO
    const isoLike = trimmed.replace(" ", "T");
    const dt1 = new Date(isoLike);
    if (!isNaN(dt1.getTime())) return dt1;
    const m = trimmed.match(/^(\d{1,2})\/(\d{1,2})\/(\d{2,4})(?:[ T](\d{1,2}):(\d{2}))?/);
    if (m) {
      const [, dd, mm, yy, hh = "0", mn = "0"] = m;
      const year = yy.length === 2 ? 2000 + Number(yy) : Number(yy);
      return new Date(year, Number(mm) - 1, Number(dd), Number(hh), Number(mn));
    }
  }
  return null;
}

function buildDeduplicationKey(
    pacienteTelefono: string,
    fechaCita: Date,
    profesional: string,
): string {
  return `${pacienteTelefono}_${fechaCita.toISOString()}_${profesional.trim().toLowerCase()}`;
}

function parseWorkbook(buffer: Buffer): {rows: ParsedRow[]; errors: string[]} {
  const wb = XLSX.read(buffer, {type: "buffer", cellDates: true});
  const sheetName = wb.SheetNames[0];
  if (!sheetName) {
    return {rows: [], errors: ["El Excel no contiene hojas"]};
  }
  const sheet = wb.Sheets[sheetName];
  const json = XLSX.utils.sheet_to_json(sheet, {
    header: 1,
    raw: true,
    defval: "",
  }) as unknown[][];
  if (json.length < 2) {
    return {rows: [], errors: ["El Excel está vacío o solo tiene cabecera"]};
  }
  const headers = json[0].map((h) => String(h ?? "").trim());
  const colNombre = findColumn(headers, COLUMN_ALIASES.pacienteNombre);
  const colTel = findColumn(headers, COLUMN_ALIASES.pacienteTelefono);
  const colFecha = findColumn(headers, COLUMN_ALIASES.fecha);
  const colHora = findColumn(headers, COLUMN_ALIASES.hora);
  const colFechaHora = findColumn(headers, COLUMN_ALIASES.fechaHora);
  const colProf = findColumn(headers, COLUMN_ALIASES.profesional);
  const colServ = findColumn(headers, COLUMN_ALIASES.servicio);
  const colNotas = findColumn(headers, COLUMN_ALIASES.notas);

  const requiredMissing: string[] = [];
  if (colNombre < 0) requiredMissing.push("Paciente/Nombre");
  if (colTel < 0) requiredMissing.push("Teléfono");
  if (colFecha < 0 && colFechaHora < 0) requiredMissing.push("Fecha");
  if (colProf < 0) requiredMissing.push("Profesional");
  if (requiredMissing.length > 0) {
    return {
      rows: [],
      errors: [`Faltan columnas obligatorias: ${requiredMissing.join(", ")}`],
    };
  }

  const rows: ParsedRow[] = [];
  const errors: string[] = [];

  for (let i = 1; i < json.length; i++) {
    const row = json[i];
    if (!row || row.length === 0) continue;
    try {
      const nombre = String(row[colNombre] ?? "").trim();
      const telRaw = String(row[colTel] ?? "").trim();
      if (!nombre || !telRaw) {
        continue; // fila vacía o incompleta, ignorar silenciosamente
      }
      let fecha: Date | null = null;
      if (colFechaHora >= 0) {
        fecha = parseDate(row[colFechaHora]);
      } else {
        const dia = parseDate(row[colFecha]);
        const horaRaw = colHora >= 0 ? row[colHora] : null;
        if (dia) {
          fecha = new Date(dia);
          if (typeof horaRaw === "string") {
            const m = horaRaw.match(/(\d{1,2}):(\d{2})/);
            if (m) {
              fecha.setHours(Number(m[1]), Number(m[2]), 0, 0);
            }
          } else if (typeof horaRaw === "number") {
            // Hora como fracción de día
            const totalSec = Math.round(horaRaw * 86400);
            fecha.setHours(Math.floor(totalSec / 3600));
            fecha.setMinutes(Math.floor((totalSec % 3600) / 60));
          }
        }
      }
      if (!fecha || isNaN(fecha.getTime())) {
        errors.push(`Fila ${i + 1}: fecha inválida (${row[colFecha] ?? row[colFechaHora]})`);
        continue;
      }
      const profesional = String(row[colProf] ?? "").trim();
      if (!profesional) {
        errors.push(`Fila ${i + 1}: profesional vacío`);
        continue;
      }
      rows.push({
        pacienteNombre: nombre,
        pacienteTelefono: normalizePhone(telRaw),
        fechaCita: fecha,
        profesional,
        servicio: colServ >= 0 ? String(row[colServ] ?? "").trim() : "",
        notas: colNotas >= 0 ? String(row[colNotas] ?? "").trim() : "",
      });
    } catch (e) {
      errors.push(`Fila ${i + 1}: ${String(e)}`);
    }
  }
  return {rows, errors};
}

export const importClinniAppointments = onRequest(
    {
      region: "europe-southwest1",
      memory: "512MiB",
      timeoutSeconds: 300,
      cors: true,
    },
    async (req, res) => {
      if (req.method !== "POST") {
        res.status(405).json({error: "Solo POST"});
        return;
      }
      const callerUid = await verifyAdminBearer(req, res);
      if (!callerUid) return;

      const {fileBase64, fileName} = (req.body ?? {}) as {
        fileBase64?: string;
        fileName?: string;
      };
      if (!fileBase64 || typeof fileBase64 !== "string") {
        res.status(400).json({error: "Falta fileBase64"});
        return;
      }
      const safeName = (fileName ?? "import.xlsx").replace(/[^a-zA-Z0-9._-]/g, "_");

      let buffer: Buffer;
      try {
        buffer = Buffer.from(fileBase64, "base64");
      } catch {
        res.status(400).json({error: "Base64 inválido"});
        return;
      }
      if (buffer.byteLength === 0) {
        res.status(400).json({error: "Archivo vacío"});
        return;
      }
      if (buffer.byteLength > 15 * 1024 * 1024) {
        res.status(400).json({error: "Archivo > 15MB"});
        return;
      }

      const {rows, errors} = parseWorkbook(buffer);
      functions.logger.info("Clinni Excel parseado", {
        fileName: safeName,
        rows: rows.length,
        errors: errors.length,
      });

      let imported = 0;
      let duplicates = 0;
      const importedAt = admin.firestore.FieldValue.serverTimestamp();

      // Insertar en lotes de 400 (límite Firestore 500/batch)
      for (let i = 0; i < rows.length; i += 400) {
        const slice = rows.slice(i, i + 400);
        const dedupKeys = slice.map((r) =>
          buildDeduplicationKey(r.pacienteTelefono, r.fechaCita, r.profesional),
        );
        // Comprobar duplicados existentes
        const existing = await db
            .collection("clinni_appointments")
            .where("deduplicationKey", "in", dedupKeys.slice(0, 30))
            .get();
        const existingKeys = new Set(
            existing.docs.map((d) => d.data().deduplicationKey as string),
        );
        // Para más de 30 hay que iterar; lo hacemos por simplicidad si hay
        if (dedupKeys.length > 30) {
          // Comprobar el resto en chunks de 30
          for (let j = 30; j < dedupKeys.length; j += 30) {
            const subKeys = dedupKeys.slice(j, j + 30);
            const sub = await db
                .collection("clinni_appointments")
                .where("deduplicationKey", "in", subKeys)
                .get();
            for (const d of sub.docs) {
              existingKeys.add(d.data().deduplicationKey as string);
            }
          }
        }

        const batch = db.batch();
        for (const row of slice) {
          const key = buildDeduplicationKey(row.pacienteTelefono, row.fechaCita, row.profesional);
          if (existingKeys.has(key)) {
            duplicates++;
            continue;
          }
          const ref = db.collection("clinni_appointments").doc();
          batch.set(ref, {
            pacienteNombre: row.pacienteNombre,
            pacienteTelefono: row.pacienteTelefono,
            fechaCita: admin.firestore.Timestamp.fromDate(row.fechaCita),
            profesional: row.profesional,
            servicio: row.servicio,
            estado: "pendiente",
            recordatorioEnviado: false,
            fechaRecordatorio: null,
            deduplicationKey: key,
            importadoEn: importedAt,
            origenExcel: safeName,
            notas: row.notas,
          });
          imported++;
        }
        await batch.commit();
      }

      // Audit log
      try {
        await db.collection("audit_logs").add({
          tipo: "CLINNI_IMPORT",
          userId: callerUid,
          timestamp: importedAt,
          metadata: {
            fileName: safeName,
            imported,
            duplicates,
            errors: errors.length,
            totalRows: rows.length,
          },
          status: "SUCCESS",
        });
      } catch (e) {
        functions.logger.warn("audit_logs write failed", e);
      }

      res.status(200).json({
        imported,
        duplicates,
        errors: errors.length,
        errorMessages: errors.slice(0, 20),
      });
    },
);

// ─── Importación de pacientes (clinni_patients) ──────────────────────────

const PATIENT_COLUMN_ALIASES = {
  numeroHistoria: ["número de historia", "numero de historia", "historia", "nº historia",
    "n historia", "history number", "id paciente"],
  nombre: ["nombre"],
  apellidos: ["apellidos", "apellido"],
  nombreCompleto: ["nombrecompleto", "nombre completo", "fullname"],
  sexo: ["sexo", "género", "genero", "gender"],
  dni: ["dni", "nif", "documento"],
  telefono: ["teléfono", "telefono", "móvil", "movil", "tel", "phone"],
  email: ["email", "correo", "e-mail"],
  fechaNacimiento: ["fecha nacimiento", "fecha de nacimiento", "f. nacimiento", "birth"],
  derivadoPor: ["derivado por", "derivado", "referido por"],
  etiquetas: ["etiquetas", "tags", "labels"],
  recibirMailing: ["recibir mailing", "mailing", "consentimiento marketing"],
  proteccionDatos: ["protección de datos firmada", "proteccion de datos firmada",
    "rgpd", "consentimiento rgpd", "proteccion datos"],
  infoSegundoTutor: ["info 2º tutor/a", "info 2º tutor", "info segundo tutor",
    "tutor secundario"],
};

interface ParsedPatient {
  numeroHistoria: string;
  nombreCompleto: string;
  sexo: string;
  dni: string;
  telefono: string;
  email: string;
  fechaNacimiento: Date | null;
  derivadoPor: string;
  etiquetas: string[];
  recibirMailing: boolean;
  proteccionDatosFirmada: boolean;
  infoSegundoTutor: string;
}

function parseBoolCell(raw: unknown): boolean {
  if (raw === undefined || raw === null) return false;
  if (typeof raw === "boolean") return raw;
  if (typeof raw === "number") return raw !== 0;
  const s = String(raw).trim().toLowerCase();
  return ["sí", "si", "yes", "y", "true", "1", "x", "✓", "✔"].includes(s);
}

function parsePatientWorkbook(
    buffer: Buffer,
): {rows: ParsedPatient[]; errors: string[]} {
  const wb = XLSX.read(buffer, {type: "buffer", cellDates: true});
  const sheetName = wb.SheetNames[0];
  if (!sheetName) {
    return {rows: [], errors: ["El Excel no contiene hojas"]};
  }
  const sheet = wb.Sheets[sheetName];
  const json = XLSX.utils.sheet_to_json(sheet, {
    header: 1,
    raw: true,
    defval: "",
  }) as unknown[][];
  if (json.length < 2) {
    return {rows: [], errors: ["El Excel está vacío o solo tiene cabecera"]};
  }
  const headers = json[0].map((h) => String(h ?? "").trim());
  const cols = {
    numeroHistoria: findColumn(headers, PATIENT_COLUMN_ALIASES.numeroHistoria),
    nombre: findColumn(headers, PATIENT_COLUMN_ALIASES.nombre),
    apellidos: findColumn(headers, PATIENT_COLUMN_ALIASES.apellidos),
    nombreCompleto: findColumn(headers, PATIENT_COLUMN_ALIASES.nombreCompleto),
    sexo: findColumn(headers, PATIENT_COLUMN_ALIASES.sexo),
    dni: findColumn(headers, PATIENT_COLUMN_ALIASES.dni),
    telefono: findColumn(headers, PATIENT_COLUMN_ALIASES.telefono),
    email: findColumn(headers, PATIENT_COLUMN_ALIASES.email),
    fechaNacimiento: findColumn(headers, PATIENT_COLUMN_ALIASES.fechaNacimiento),
    derivadoPor: findColumn(headers, PATIENT_COLUMN_ALIASES.derivadoPor),
    etiquetas: findColumn(headers, PATIENT_COLUMN_ALIASES.etiquetas),
    recibirMailing: findColumn(headers, PATIENT_COLUMN_ALIASES.recibirMailing),
    proteccionDatos: findColumn(headers, PATIENT_COLUMN_ALIASES.proteccionDatos),
    infoSegundoTutor: findColumn(headers, PATIENT_COLUMN_ALIASES.infoSegundoTutor),
  };

  if (cols.telefono < 0) {
    return {rows: [], errors: ["Falta columna obligatoria: Teléfono"]};
  }

  const rows: ParsedPatient[] = [];
  const errors: string[] = [];

  for (let i = 1; i < json.length; i++) {
    const row = json[i];
    if (!row || row.length === 0) continue;
    try {
      const telRaw = String(row[cols.telefono] ?? "").trim();
      if (!telRaw) continue; // sin teléfono no podemos identificar

      const nombre = cols.nombre >= 0 ? String(row[cols.nombre] ?? "").trim() : "";
      const apellidos = cols.apellidos >= 0 ? String(row[cols.apellidos] ?? "").trim() : "";
      const nombreCompletoRaw = cols.nombreCompleto >= 0 ?
        String(row[cols.nombreCompleto] ?? "").trim() : "";
      const nombreCompleto = nombreCompletoRaw ||
        `${nombre} ${apellidos}`.trim() ||
        "(sin nombre)";

      const etiquetasRaw = cols.etiquetas >= 0 ?
        String(row[cols.etiquetas] ?? "").trim() : "";
      const etiquetas = etiquetasRaw ?
        etiquetasRaw.split(/[,;|]/).map((e) => e.trim()).filter((e) => e) :
        [];

      rows.push({
        numeroHistoria: cols.numeroHistoria >= 0 ?
          String(row[cols.numeroHistoria] ?? "").trim() : "",
        nombreCompleto,
        sexo: cols.sexo >= 0 ? String(row[cols.sexo] ?? "").trim() : "",
        dni: cols.dni >= 0 ? String(row[cols.dni] ?? "").trim() : "",
        telefono: normalizePhone(telRaw),
        email: cols.email >= 0 ? String(row[cols.email] ?? "").trim() : "",
        fechaNacimiento: cols.fechaNacimiento >= 0 ?
          parseDate(row[cols.fechaNacimiento]) : null,
        derivadoPor: cols.derivadoPor >= 0 ?
          String(row[cols.derivadoPor] ?? "").trim() : "",
        etiquetas,
        recibirMailing: cols.recibirMailing >= 0 ?
          parseBoolCell(row[cols.recibirMailing]) : false,
        proteccionDatosFirmada: cols.proteccionDatos >= 0 ?
          parseBoolCell(row[cols.proteccionDatos]) : false,
        infoSegundoTutor: cols.infoSegundoTutor >= 0 ?
          String(row[cols.infoSegundoTutor] ?? "").trim() : "",
      });
    } catch (e) {
      errors.push(`Fila ${i + 1}: ${String(e)}`);
    }
  }
  return {rows, errors};
}

/**
 * Importa pacientes desde el Excel `listado_v26.xlsx` de Clinni a la
 * colección `clinni_patients`. El `telefono` normalizado se usa como
 * doc ID para que reimportar el mismo paciente sobrescriba (idempotente).
 *
 * Solo admin/administrador pueden invocar.
 */
export const importClinniPatients = onRequest(
    {
      region: "europe-southwest1",
      memory: "512MiB",
      timeoutSeconds: 540,
      cors: true,
    },
    async (req, res) => {
      if (req.method !== "POST") {
        res.status(405).json({error: "Solo POST"});
        return;
      }
      const callerUid = await verifyAdminBearer(req, res);
      if (!callerUid) return;

      const {fileBase64, fileName} = (req.body ?? {}) as {
        fileBase64?: string;
        fileName?: string;
      };
      if (!fileBase64 || typeof fileBase64 !== "string") {
        res.status(400).json({error: "Falta fileBase64"});
        return;
      }
      const safeName = (fileName ?? "import_pacientes.xlsx")
          .replace(/[^a-zA-Z0-9._-]/g, "_");

      let buffer: Buffer;
      try {
        buffer = Buffer.from(fileBase64, "base64");
      } catch {
        res.status(400).json({error: "Base64 inválido"});
        return;
      }
      if (buffer.byteLength === 0) {
        res.status(400).json({error: "Archivo vacío"});
        return;
      }
      if (buffer.byteLength > 30 * 1024 * 1024) {
        res.status(400).json({error: "Archivo > 30MB"});
        return;
      }

      const {rows, errors} = parsePatientWorkbook(buffer);
      functions.logger.info("Clinni pacientes Excel parseado", {
        fileName: safeName,
        rows: rows.length,
        errors: errors.length,
      });

      let imported = 0;
      let updated = 0;
      const importedAt = admin.firestore.FieldValue.serverTimestamp();

      // Procesamos en batches de 400. Cada paciente se identifica por
      // telefono normalizado como doc ID. Antes del set comprobamos
      // existencia para distinguir imported vs updated en el reporte.
      for (let i = 0; i < rows.length; i += 400) {
        const slice = rows.slice(i, i + 400);
        const ids = slice.map((r) => r.telefono);

        // Comprobar cuáles ya existen (en chunks de 30 por la limitación
        // de Firestore "in" queries).
        const existingIds = new Set<string>();
        for (let j = 0; j < ids.length; j += 30) {
          const sub = ids.slice(j, j + 30);
          const snap = await db
              .collection("clinni_patients")
              .where(admin.firestore.FieldPath.documentId(), "in", sub)
              .get();
          for (const d of snap.docs) {
            existingIds.add(d.id);
          }
        }

        const batch = db.batch();
        for (const r of slice) {
          if (!r.telefono) continue;
          const ref = db.collection("clinni_patients").doc(r.telefono);
          batch.set(ref, {
            numeroHistoria: r.numeroHistoria,
            nombreCompleto: r.nombreCompleto,
            sexo: r.sexo,
            dni: r.dni,
            telefono: r.telefono,
            email: r.email,
            fechaNacimiento: r.fechaNacimiento ?
              admin.firestore.Timestamp.fromDate(r.fechaNacimiento) :
              null,
            derivadoPor: r.derivadoPor,
            etiquetas: r.etiquetas,
            recibirMailing: r.recibirMailing,
            proteccionDatosFirmada: r.proteccionDatosFirmada,
            infoSegundoTutor: r.infoSegundoTutor,
            origenExcel: safeName,
            importadoEn: importedAt,
          }, {merge: true});
          if (existingIds.has(r.telefono)) updated++;
          else imported++;
        }
        await batch.commit();
      }

      // Audit log
      try {
        await db.collection("audit_logs").add({
          tipo: "CLINNI_PATIENTS_IMPORT",
          userId: callerUid,
          timestamp: importedAt,
          metadata: {
            fileName: safeName,
            imported,
            updated,
            errors: errors.length,
            totalRows: rows.length,
          },
          status: "SUCCESS",
        });
      } catch (e) {
        functions.logger.warn("audit_logs write failed", e);
      }

      res.status(200).json({
        imported,
        updated,
        errors: errors.length,
        errorMessages: errors.slice(0, 20),
      });
    },
);
