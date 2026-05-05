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
  pacienteTelefono: string; // "" si el Excel no trae teléfono → enriquecer después
  fechaCita: Date;
  profesional: string;
  servicio: string;
  notas: string;
  estadoOriginal: string; // Lo que pone el Excel: "Atendida"/"Ausente"/"Pendiente"/...
}

const COLUMN_ALIASES = {
  pacienteNombre: ["paciente", "nombre", "cliente"],
  pacienteTelefono: ["telefono", "teléfono", "movil", "móvil", "tel", "celular", "phone"],
  fecha: ["fecha", "fecha cita", "fecha de la cita", "fechacita", "date"],
  hora: ["hora", "hora cita", "horacita", "time", "inicio cita", "inicio"],
  fechaHora: ["fecha y hora", "fechahora", "datetime"],
  profesional: ["profesional", "doctor", "doctora", "médico", "medico", "terapeuta",
    "atendida por", "atendido por", "atiende"],
  servicio: ["servicio", "tratamiento", "tipo", "tipo cita", "service", "proceso"],
  notas: ["notas", "observaciones", "comentarios", "notes"],
  estado: ["estado", "status"],
};

/**
 * Normaliza un nombre para comparación: minúsculas, sin acentos, sin
 * dobles espacios. Usado para hacer match cruzado entre el "Paciente"
 * del Excel de citas y el "nombreCompleto" de clinni_patients cuando
 * el Excel de citas no incluye teléfono.
 */
function normalizeName(s: string): string {
  return (s ?? "")
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "")
      .toLowerCase()
      .trim()
      .replace(/\s+/g, " ");
}

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

/**
 * Construye un Date que representa "year-month-day hh:mm en Europe/Madrid"
 * como instante UTC. Necesario porque el servidor Cloud Functions corre
 * en UTC y `new Date(y,m,d,h,m)` interpretaría los args como UTC, lo que
 * da el horario erróneo. Maneja DST correctamente (CEST verano UTC+2,
 * CET invierno UTC+1).
 */
function buildMadridDate(
    year: number, monthIdx0: number, day: number, hh: number, mm: number,
): Date {
  // Truco: creamos un sample en UTC con esos valores. Luego calculamos
  // qué offset tiene Madrid en ESE momento y lo restamos.
  const sample = new Date(Date.UTC(year, monthIdx0, day, hh, mm));
  const localMadrid = new Date(
      sample.toLocaleString("en-US", {timeZone: "Europe/Madrid"}),
  );
  const utcEquiv = new Date(
      sample.toLocaleString("en-US", {timeZone: "UTC"}),
  );
  const offsetMs = localMadrid.getTime() - utcEquiv.getTime();
  return new Date(sample.getTime() - offsetMs);
}

/**
 * Convierte un Date "naive" (creado en TZ del servidor UTC pero que
 * debería interpretarse como hora Madrid) al instante UTC correcto.
 * Útil cuando xlsx con cellDates:true devuelve Dates "naive" en mayo
 * que serían 9:30 UTC pero el autor del Excel quiso decir 9:30 Madrid.
 */
function reinterpretAsMadrid(naive: Date): Date {
  return buildMadridDate(
      naive.getUTCFullYear(),
      naive.getUTCMonth(),
      naive.getUTCDate(),
      naive.getUTCHours(),
      naive.getUTCMinutes(),
  );
}

function parseDate(raw: unknown): Date | null {
  if (!raw) return null;
  // Excel cellDates:true devuelve Dates "naive" en UTC que representan
  // la hora Madrid del autor. Reinterpretamos.
  if (raw instanceof Date) return reinterpretAsMadrid(raw);
  if (typeof raw === "number") {
    // Excel serial date (días desde 1900-01-01). Reinterpretado como Madrid.
    const utcDays = Math.floor(raw - 25569);
    const utcMs = utcDays * 86400 * 1000;
    const fractional = raw - Math.floor(raw);
    const naive = new Date(utcMs + fractional * 86400 * 1000);
    return reinterpretAsMadrid(naive);
  }
  if (typeof raw === "string") {
    const trimmed = raw.trim();
    if (!trimmed) return null;
    // Solo aceptamos DD/MM/YYYY (formato España de Clinni). NO usamos
    // new Date(string) porque interpreta MM/DD ambiguamente.
    const m = trimmed.match(/^(\d{1,2})\/(\d{1,2})\/(\d{2,4})(?:[ T](\d{1,2}):(\d{2}))?/);
    if (m) {
      const [, dd, mm, yy, hh = "0", mn = "0"] = m;
      const year = yy.length === 2 ? 2000 + Number(yy) : Number(yy);
      return buildMadridDate(year, Number(mm) - 1, Number(dd), Number(hh), Number(mn));
    }
    // Formato ISO YYYY-MM-DD HH:MM (también de Madrid si Clinni lo usa).
    const iso = trimmed.match(/^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{1,2}):(\d{2}))?/);
    if (iso) {
      const [, yy, mm, dd, hh = "0", mn = "0"] = iso;
      return buildMadridDate(Number(yy), Number(mm) - 1, Number(dd), Number(hh), Number(mn));
    }
  }
  return null;
}

/**
 * Mapea el estado del Excel Clinni al estado normalizado de Firestore.
 * Estados del modelo: pendiente, confirmada, cancelada, atendida, ausente,
 * vencida, reagendada.
 */
function mapEstadoExcel(estadoExcel: string): string {
  const e = estadoExcel.toLowerCase().trim();
  if (e === "atendida" || e === "facturada") return "atendida";
  if (e === "ausente") return "ausente";
  if (["cancelada", "cancelado", "anulada", "anulado"].includes(e)) return "cancelada";
  if (e === "pendiente") return "pendiente";
  return "pendiente";
}

function buildDeduplicationKey(
    pacienteTelefono: string,
    fechaCita: Date,
    profesional: string,
    fallbackNombre = "",
): string {
  // Si no hay teléfono, usamos nombre normalizado como discriminante para
  // que dos pacientes distintos sin teléfono el mismo día/profesional no
  // colapsen en el mismo doc.
  const id = pacienteTelefono ||
    `notel_${normalizeName(fallbackNombre).replace(/\s+/g, "_")}`;
  return `${id}_${fechaCita.toISOString()}_${profesional.trim().toLowerCase()}`;
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
  const colEstado = findColumn(headers, COLUMN_ALIASES.estado);

  // Teléfono es OPCIONAL: el informe de citas de Clinni no incluye
  // teléfono, así que si falta lo enriqueceremos cruzando por
  // nombreCompleto contra clinni_patients después del parseo.
  const requiredMissing: string[] = [];
  if (colNombre < 0) requiredMissing.push("Paciente/Nombre");
  if (colFecha < 0 && colFechaHora < 0) requiredMissing.push("Fecha");
  if (colProf < 0) requiredMissing.push("Profesional/Atendida por");
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
      const telRaw = colTel >= 0 ? String(row[colTel] ?? "").trim() : "";
      if (!nombre) {
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
        pacienteTelefono: telRaw ? normalizePhone(telRaw) : "",
        fechaCita: fecha,
        profesional,
        servicio: colServ >= 0 ? String(row[colServ] ?? "").trim() : "",
        notas: colNotas >= 0 ? String(row[colNotas] ?? "").trim() : "",
        estadoOriginal: colEstado >= 0 ? String(row[colEstado] ?? "").trim() : "",
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
      try {
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

        const {rows: rawRows, errors} = parseWorkbook(buffer);

        // 1) Enriquecer teléfono cruzando por nombre con clinni_patients
        //    (el informe de citas de Clinni no incluye teléfono).
        const needsPhoneEnrichment = rawRows.some((r) => !r.pacienteTelefono);
        let nameToPhone = new Map<string, string>();
        const ambiguousNames = new Set<string>();
        if (needsPhoneEnrichment) {
          const snap = await db.collection("clinni_patients").get();
          for (const d of snap.docs) {
            const data = d.data();
            const tel = String(data.telefono ?? d.id);
            const nombre = normalizeName(String(data.nombreCompleto ?? ""));
            if (!nombre) continue;
            if (nameToPhone.has(nombre)) {
              ambiguousNames.add(nombre);
            } else {
              nameToPhone.set(nombre, tel);
            }
          }
          functions.logger.info("Cruce nombre→telefono", {
            patientsLoaded: snap.size,
            uniqueNames: nameToPhone.size,
            ambiguous: ambiguousNames.size,
          });
        }

        // 2) Procesar filas. Política tras feedback usuario:
        //    - Citas pasadas: descartar (el bot solo gestiona futuras).
        //    - Estados finalizados (atendida/facturada/cancelada/ausente):
        //      NO descartar — vamos a ACTUALIZAR la cita existente en
        //      Firestore si está como pendiente. Si no existe, no la
        //      creamos (sin sentido).
        //    - Sin teléfono: importar igualmente con flag requiereRevision
        //      para que aparezca en pestaña "Citas con problema". El admin
        //      las edita manual.
        //    - Nombre ambiguo: idem, requiereRevision con motivo claro.
        const now = new Date();
        let skippedPast = 0;
        let skippedNoMatchDoneState = 0;
        const noEncontrados: string[] = []; // para reporte CSV (#17)
        const rows: ParsedRow[] = [];
        const DONE_STATES = ["atendida", "facturada", "ausente",
          "cancelada", "cancelado", "anulada", "anulado"];

        for (const r of rawRows) {
          // Filtrar pasadas (no útiles para recordatorios futuros)
          if (r.fechaCita.getTime() < now.getTime()) {
            skippedPast++;
            continue;
          }

          // Marcar motivo de requiereRevision (#10)
          let motivoRevision: string | null = null;
          if (!r.pacienteTelefono) {
            const norm = normalizeName(r.pacienteNombre);
            if (ambiguousNames.has(norm)) {
              motivoRevision = "nombre_ambiguo";
              noEncontrados.push(`${r.pacienteNombre} (ambiguo)`);
            } else {
              const tel = nameToPhone.get(norm);
              if (!tel) {
                motivoRevision = "sin_telefono";
                noEncontrados.push(r.pacienteNombre);
              } else {
                r.pacienteTelefono = tel;
              }
            }
          }

          // Estado finalizado: solo nos sirve para ACTUALIZAR. Si no existe
          // en Firestore Y no se puede asociar a un dedup key claro, descartar.
          const estadoNorm = r.estadoOriginal.toLowerCase().trim();
          const isDoneState = DONE_STATES.includes(estadoNorm);
          if (isDoneState && motivoRevision) {
            // Sin tel, no puedo construir dedupKey estable → descarto.
            skippedNoMatchDoneState++;
            continue;
          }

          // Cast sutil: añadimos runtime fields a la fila parsed.
          (r as ParsedRow & {
            requiereRevision: boolean;
            motivoRevision: string | null;
            isDoneState: boolean;
            estadoFinalNormalizado: string | null;
          }).requiereRevision = motivoRevision !== null;
          (r as unknown as {motivoRevision: string | null}).motivoRevision = motivoRevision;
          (r as unknown as {isDoneState: boolean}).isDoneState = isDoneState;
          (r as unknown as {estadoFinalNormalizado: string | null})
              .estadoFinalNormalizado = isDoneState ? mapEstadoExcel(estadoNorm) : null;
          rows.push(r);
        }
        if (skippedPast > 0) {
          errors.push(`${skippedPast} cita(s) descartadas: fecha pasada (el bot solo procesa citas futuras)`);
        }
        if (skippedNoMatchDoneState > 0) {
          errors.push(`${skippedNoMatchDoneState} cita(s) descartadas: estado finalizado y paciente sin teléfono (no se pudo asociar)`);
        }
        const requierenRevision = rows.filter((r) => (r as unknown as {requiereRevision: boolean}).requiereRevision).length;
        if (requierenRevision > 0) {
          errors.push(`${requierenRevision} cita(s) importadas SIN teléfono — revisa la pestaña "Citas con problema" del panel`);
        }

        functions.logger.info("Clinni Excel parseado", {
          fileName: safeName,
          rawRows: rawRows.length,
          rows: rows.length,
          requierenRevision,
          skippedPast,
          skippedNoMatchDoneState,
          errors: errors.length,
        });

        let imported = 0;
        let updated = 0;
        let updatedSkipped = 0;
        let skippedDoneNotFound = 0;
        const importedAt = admin.firestore.FieldValue.serverTimestamp();
        nameToPhone = new Map();

        // Cargamos TODAS las citas existentes en memoria una sola vez para
        // hacer upsert eficiente. Tamaño manejable (cientos a miles de docs).
        const allExistingByKey = new Map<string, FirebaseFirestore.QueryDocumentSnapshot>();
        try {
          const existingSnap = await db.collection("clinni_appointments").get();
          for (const d of existingSnap.docs) {
            const k = d.data().deduplicationKey as string | undefined;
            if (k) allExistingByKey.set(k, d);
          }
          functions.logger.info("Cache citas existentes", {total: existingSnap.size});
        } catch (e) {
          functions.logger.warn("No se pudo cachear citas existentes; modo solo-insertar", e);
        }

        for (let i = 0; i < rows.length; i += 400) {
          const slice = rows.slice(i, i + 400);
          const batch = db.batch();
          for (const row of slice) {
            const r = row as ParsedRow & {
              requiereRevision: boolean;
              motivoRevision: string | null;
              isDoneState: boolean;
              estadoFinalNormalizado: string | null;
            };
            const key = buildDeduplicationKey(
                r.pacienteTelefono, r.fechaCita, r.profesional, r.pacienteNombre,
            );
            const existingDoc = allExistingByKey.get(key);

            if (existingDoc) {
              // UPSERT: cita ya existe en Firestore.
              const existingData = existingDoc.data();
              const estadoActual = String(existingData.estado ?? "pendiente");
              if (r.isDoneState && r.estadoFinalNormalizado &&
                  estadoActual !== r.estadoFinalNormalizado) {
                // Excel dice "cancelada/atendida/ausente" pero Firestore aún
                // la tiene como pendiente → actualizar (resuelve cita fantasma).
                batch.update(existingDoc.ref, {
                  estado: r.estadoFinalNormalizado,
                  estadoActualizadoEn: importedAt,
                  estadoActualizadoOrigen: safeName,
                });
                updated++;
              } else {
                updatedSkipped++;
              }
              continue;
            }

            // INSERT nuevo. Si Excel ya la trae como done, no la creamos.
            if (r.isDoneState) {
              skippedDoneNotFound++;
              continue;
            }

            const ref = db.collection("clinni_appointments").doc();
            batch.set(ref, {
              pacienteNombre: r.pacienteNombre,
              pacienteTelefono: r.pacienteTelefono || "",
              fechaCita: admin.firestore.Timestamp.fromDate(r.fechaCita),
              profesional: r.profesional,
              servicio: r.servicio,
              estado: "pendiente",
              recordatorioEnviado: false,
              fechaRecordatorio: null,
              deduplicationKey: key,
              importadoEn: importedAt,
              origenExcel: safeName,
              notas: r.notas,
              // #10: flags de revisión manual
              requiereRevision: r.requiereRevision,
              motivoRevision: r.motivoRevision,
            });
            imported++;
          }
          await batch.commit();
        }
        allExistingByKey.clear();
        functions.logger.info("Importación citas resumen", {
          imported, updated, updatedSkipped, skippedDoneNotFound,
        });
        // Mantener compatibilidad de respuesta hacia atrás
        const duplicates = updatedSkipped;
        void updated; void skippedDoneNotFound;

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
          updated,
          skippedDoneNotFound,
          requierenRevision,
          errors: errors.length,
          errorMessages: errors.slice(0, 20),
          // #17: lista de nombres que no se encontraron en clinni_patients
          // (limitado a 200 para no saturar la respuesta).
          noEncontrados: noEncontrados.slice(0, 200),
        });
      } catch (e) {
        // Captura cualquier error inesperado (Firestore, memoria, timeout)
        // y devuelve JSON al cliente en vez de "Internal Server Error".
        functions.logger.error("importClinniAppointments exception", e);
        res.status(500).json({
          error: String(e),
          imported: 0,
          duplicates: 0,
          errors: 1,
          errorMessages: [String(e)],
        });
      }
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
      try {
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

        const {rows: rawRows, errors} = parsePatientWorkbook(buffer);
        // Filtramos rows con telefono inválido (normalizePhone devolvió "").
        // Quedan en `errors` para que el cliente vea cuántas se descartaron.
        const rows = rawRows.filter((r) => r.telefono);
        const skipped = rawRows.length - rows.length;
        if (skipped > 0) {
          errors.push(`${skipped} fila(s) descartadas por teléfono inválido o vacío`);
        }
        functions.logger.info("Clinni pacientes Excel parseado", {
          fileName: safeName,
          rows: rows.length,
          rawRows: rawRows.length,
          skipped,
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
      } catch (e) {
        // Captura cualquier error inesperado (Firestore INVALID_ARGUMENT,
        // memoria, timeout, etc.) y devuelve JSON al cliente en vez del
        // texto plano "Internal Server Error" que rompe el parser.
        functions.logger.error("importClinniPatients exception", e);
        res.status(500).json({
          error: String(e),
          imported: 0,
          updated: 0,
          errors: 1,
          errorMessages: [String(e)],
        });
      }
    },
);
