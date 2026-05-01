/**
 * Cloud Function `replicateClassesMonth` (HTTP onRequest, admin-only).
 *
 * Replica el patrón semanal de un mes origen a un mes destino.
 *
 * Lee `groupClasses` del mes origen (campos `mes`/`anio`), agrupa por
 * (día semana ISO + hora HH:MM + título + monitor), y crea instancias
 * en el mes destino para cada fecha que matchee el día de la semana.
 *
 * Idempotente: docId determinístico
 *   replicate_<YYYY-MM>_<YYYY-MM-DD>_<HHMM>_<slug-titulo>
 * Si ya existe, no se sobrescribe.
 *
 * Respeta `clinic_holidays`: las fechas marcadas como festivo o cerrado
 * excepcional se saltan automáticamente.
 */

import {onRequest} from "firebase-functions/v2/https";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

interface ReplicateRequest {
  sourceMonth: string; // "YYYY-MM"
  targetMonth: string; // "YYYY-MM"
  aforoMaximo?: number; // default 12
  duracionMinutos?: number; // default 60
}

interface PatternSlot {
  dowIso: number; // 1=lunes ... 7=domingo
  hora: string; // "HH:MM"
  titulo: string;
  monitor: string;
}

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
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    const userDoc = await db.collection("users_app").doc(decoded.uid).get();
    const rol = ((userDoc.data()?.rol as string) ?? "").toLowerCase();
    if (!["admin", "administrador"].includes(rol)) {
      res.status(403).json({error: "Solo admin puede invocar"});
      return null;
    }
    return decoded.uid;
  } catch {
    res.status(401).json({error: "Token inválido o expirado"});
    return null;
  }
}

function parseYM(s: string): {year: number; month: number} | null {
  const m = /^(\d{4})-(\d{2})$/.exec(s);
  if (!m) return null;
  const year = Number(m[1]);
  const month = Number(m[2]);
  if (year < 2024 || year > 2100 || month < 1 || month > 12) return null;
  return {year, month};
}

function slug(s: string): string {
  return s.toLowerCase()
      .normalize("NFD").replace(/[̀-ͯ]/g, "")
      .replace(/[^a-z0-9]+/g, "_")
      .replace(/^_+|_+$/g, "");
}

/**
 * Construye un Date que representa "year-month-day HH:MM" en TZ
 * Europe/Madrid, devolviendo el instante UTC equivalente (con DST).
 */
function buildLocalMadridDate(
    year: number, month: number, day: number, hh: number, mm: number,
): Date {
  const sample = new Date(Date.UTC(year, month - 1, day, hh, mm));
  const local = new Date(sample.toLocaleString("en-US", {timeZone: "Europe/Madrid"}));
  const utc = new Date(sample.toLocaleString("en-US", {timeZone: "UTC"}));
  const offsetMs = local.getTime() - utc.getTime();
  return new Date(sample.getTime() - offsetMs);
}

function dowIso(d: Date): number {
  const dowName = d.toLocaleString("en-US", {
    timeZone: "Europe/Madrid", weekday: "long",
  });
  const map: Record<string, number> = {
    Monday: 1, Tuesday: 2, Wednesday: 3, Thursday: 4,
    Friday: 5, Saturday: 6, Sunday: 7,
  };
  return map[dowName] ?? 0;
}

async function loadHolidaysSet(year: number, month: number): Promise<Set<string>> {
  const fromIso = `${year}-${String(month).padStart(2, "0")}-01`;
  const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate();
  const toIso = `${year}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
  const snap = await db.collection("clinic_holidays")
      .where("fecha", ">=", fromIso)
      .where("fecha", "<=", toIso)
      .get();
  const closed = new Set<string>();
  for (const d of snap.docs) {
    const data = d.data();
    if (data.tipo === "festivo" || data.tipo === "cerrado_excepcional") {
      closed.add(String(data.fecha ?? d.id));
    }
  }
  return closed;
}

async function extractPatternFromMonth(
    year: number, month: number,
): Promise<PatternSlot[]> {
  const start = new Date(Date.UTC(year, month - 1, 1));
  const end = new Date(Date.UTC(year, month, 1));
  const snap = await db.collection("groupClasses")
      .where("fechaHoraInicio", ">=", admin.firestore.Timestamp.fromDate(start))
      .where("fechaHoraInicio", "<", admin.firestore.Timestamp.fromDate(end))
      .get();

  // Dedup por clave única — si en abril hubo 4 lunes con la misma clase,
  // solo cogemos un patrón.
  const seen = new Map<string, PatternSlot>();
  for (const doc of snap.docs) {
    const d = doc.data();
    const fecha = d.fechaHoraInicio?.toDate?.();
    if (!fecha) continue;
    const dow = dowIso(fecha);
    const hora = fecha.toLocaleString("es-ES", {
      timeZone: "Europe/Madrid",
      hour: "2-digit", minute: "2-digit", hour12: false,
    });
    const titulo = String(d.titulo ?? d.nombre ?? "").trim();
    const monitor = String(d.monitor ?? d.monitorNombre ?? d.profesor ?? "").trim();
    if (!titulo) continue;
    const key = `${dow}|${hora}|${titulo}|${monitor}`;
    if (!seen.has(key)) {
      seen.set(key, {dowIso: dow, hora, titulo, monitor});
    }
  }
  return [...seen.values()];
}

export const replicateClassesMonth = onRequest(
    {
      region: "europe-southwest1",
      memory: "256MiB",
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

        const body = (req.body ?? {}) as ReplicateRequest;
        const source = parseYM(body.sourceMonth ?? "");
        const target = parseYM(body.targetMonth ?? "");
        if (!source || !target) {
          res.status(400).json({
            error: "sourceMonth y targetMonth deben tener formato YYYY-MM",
          });
          return;
        }
        const aforo = body.aforoMaximo ?? 12;
        const duracion = body.duracionMinutos ?? 60;

        functions.logger.info("replicateClassesMonth: start", {
          source, target, callerUid,
        });

        const pattern = await extractPatternFromMonth(source.year, source.month);
        if (pattern.length === 0) {
          res.status(200).json({
            created: 0, alreadyExisted: 0, skippedHolidays: 0,
            message: `No se encontraron clases en ${body.sourceMonth} para replicar`,
          });
          return;
        }

        const closed = await loadHolidaysSet(target.year, target.month);
        const lastDay = new Date(Date.UTC(target.year, target.month, 0)).getUTCDate();

        let created = 0;
        let alreadyExisted = 0;
        let skippedHolidays = 0;
        const errors: string[] = [];

        const ymKey = `${target.year}-${String(target.month).padStart(2, "0")}`;

        for (let day = 1; day <= lastDay; day++) {
          const date = new Date(Date.UTC(target.year, target.month - 1, day));
          const dow = dowIso(date);
          const slots = pattern.filter((p) => p.dowIso === dow);
          if (slots.length === 0) continue;

          const isoDate = `${ymKey}-${String(day).padStart(2, "0")}`;
          if (closed.has(isoDate)) {
            skippedHolidays += slots.length;
            continue;
          }

          for (const s of slots) {
            const [hh, mm] = s.hora.split(":").map(Number);
            const fechaInicio = buildLocalMadridDate(
                target.year, target.month, day, hh, mm,
            );
            const fechaFin = new Date(fechaInicio.getTime() + duracion * 60 * 1000);
            const docId = `replicate_${ymKey}_${isoDate}_${
              String(hh).padStart(2, "0")}${String(mm).padStart(2, "0")}_${slug(s.titulo)}`;

            const ref = db.collection("groupClasses").doc(docId);
            try {
              const snap = await ref.get();
              if (snap.exists) {
                alreadyExisted++;
                continue;
              }
              await ref.set({
                nombre: s.titulo,
                titulo: s.titulo,
                monitor: s.monitor,
                monitorNombre: s.monitor,
                fechaHoraInicio: admin.firestore.Timestamp.fromDate(fechaInicio),
                fechaHoraFin: admin.firestore.Timestamp.fromDate(fechaFin),
                duracionMinutos: duracion,
                aforoMaximo: aforo,
                aforoActual: 0,
                mes: target.month,
                anio: target.year,
                dia: day,
                diaSemana: dow,
                horaInicio: s.hora,
                activa: true,
                origen: "replicate_classes_month",
                origenSource: body.sourceMonth,
                creadoEn: admin.firestore.FieldValue.serverTimestamp(),
                creadoPor: callerUid,
              });
              created++;
            } catch (e) {
              errors.push(`${docId}: ${String(e)}`);
            }
          }
        }

        // Audit log
        try {
          await db.collection("audit_logs").add({
            tipo: "REPLICATE_CLASSES_MONTH",
            userId: callerUid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
              sourceMonth: body.sourceMonth,
              targetMonth: body.targetMonth,
              created, alreadyExisted, skippedHolidays,
              patternsExtracted: pattern.length,
            },
            status: "SUCCESS",
          });
        } catch (e) {
          functions.logger.warn("audit_logs falló", {error: String(e)});
        }

        functions.logger.info("replicateClassesMonth: done", {
          created, alreadyExisted, skippedHolidays,
        });
        res.status(200).json({
          created,
          alreadyExisted,
          skippedHolidays,
          patternsExtracted: pattern.length,
          errors: errors.slice(0, 10),
        });
      } catch (e) {
        functions.logger.error("replicateClassesMonth exception", e);
        res.status(500).json({error: String(e)});
      }
    },
);
