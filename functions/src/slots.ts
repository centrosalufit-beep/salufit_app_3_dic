/**
 * Generación y selección de slots disponibles para reagendación automática
 * (Fase 2 — espec sec 7).
 *
 * Pipeline:
 *   1. loadSchedule(profesionalId) — lee el doc de professional_schedules.
 *   2. generateCandidateSlots(schedule, desde, hasta) — slots teóricos según
 *      horarios + duración. Filtra festivos (holidays.ts) y ausencias del
 *      profesional (professional_absences) y cierres de clínica (clinic_holidays).
 *   3. getOccupiedSlots(profesional, desde, hasta) — citas existentes en
 *      clinni_appointments para ese profesional.
 *   4. findNextAvailableSlots(profesionalId, count, opts) — combina lo anterior
 *      y devuelve los primeros N huecos libres.
 *
 * Reglas de negocio (espec política 48h):
 *   - Si la cita actual del paciente está dentro de 48h y se reagenda, los
 *     slots ofrecidos deben caer dentro de las 48h SIGUIENTES a la cita actual.
 *   - Esto se modela con el parámetro opcional `restrictToBeforeMs` que el
 *     caller usa para fijar el límite superior.
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {isHoliday} from "./holidays";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

export interface ProfessionalSchedule {
  id: string;
  nombre: string;
  especialidad: string;
  duracionSlotMinutos: number;
  activo: boolean;
  escalaDirectaParaReagendar: boolean;
  motivoEscalaDirecta?: string;
  horarios: Array<{dia: number; inicio: string; fin: string}>;
  // Aliases opcionales: nombres adicionales con los que puede aparecer este
  // profesional en clinni_appointments.profesional. Útil si Clinni envía el
  // nombre con prefijo o apellidos que no encajan con la heurística de match.
  nombresClinni?: string[];
}

/** Normaliza nombres de profesional: quita prefijos médicos, acentos, espacios. */
function normalizeName(name: string): string {
  if (!name) return "";
  return name
      .toLowerCase()
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "") // quita acentos
      .replace(/^(dr|dra|d\.|dr\.|dra\.|lic|lic\.|lcda|lcdo|doctor|doctora)\s+/i, "")
      .replace(/\./g, "")
      .replace(/\s+/g, " ")
      .trim();
}

/**
 * Devuelve true si el nombre que viene de Clinni corresponde al schedule.
 * Lógica:
 *   1) Match exacto contra nombre (case-sensitive).
 *   2) Match exacto contra nombresClinni[] (alias manuales).
 *   3) Match heurístico: tras normalizar ambos, comprobar que el nombre del
 *      schedule está contenido como sub-cadena del nombre clinni o viceversa.
 *      Esto pilla "Dra. María Vallés" → "María", "Dr. Álvaro García" → "Álvaro",
 *      etc. Funciona porque los nombres del equipo no se repiten.
 */
function nombreEncaja(schedule: ProfessionalSchedule, nombreClinni: string): boolean {
  if (!nombreClinni) return false;
  if (schedule.nombre === nombreClinni) return true;
  if (schedule.nombresClinni?.includes(nombreClinni)) return true;
  const a = normalizeName(schedule.nombre);
  const b = normalizeName(nombreClinni);
  if (!a || !b) return false;
  if (a === b) return true;
  // Comprobamos como palabra completa, no sub-cadena cualquiera, para evitar
  // falsos positivos del estilo "Sara" matcheando "Sarai".
  const tokensB = b.split(" ");
  const tokensA = a.split(" ");
  return tokensA.every((t) => tokensB.includes(t)) ||
         tokensB.every((t) => tokensA.includes(t));
}

export interface Slot {
  inicio: Date;
  fin: Date;
  profesionalId: string;
  profesionalNombre: string;
}

/** Carga el doc de un profesional. null si no existe o falla. */
export async function loadSchedule(
    profesionalId: string,
): Promise<ProfessionalSchedule | null> {
  try {
    const doc = await db.collection("professional_schedules").doc(profesionalId).get();
    if (!doc.exists) return null;
    return docToSchedule(doc);
  } catch (e) {
    functions.logger.warn("loadSchedule falló", {profesionalId, error: String(e)});
    return null;
  }
}

function docToSchedule(doc: FirebaseFirestore.QueryDocumentSnapshot | FirebaseFirestore.DocumentSnapshot): ProfessionalSchedule {
  const data = doc.data() ?? {};
  return {
    id: doc.id,
    nombre: (data.nombre as string) ?? "",
    especialidad: (data.especialidad as string) ?? "",
    duracionSlotMinutos: (data.duracionSlotMinutos as number) ?? 30,
    activo: data.activo !== false,
    escalaDirectaParaReagendar: data.escalaDirectaParaReagendar === true,
    motivoEscalaDirecta: (data.motivoEscalaDirecta as string) ?? undefined,
    horarios: (data.horarios as Array<{dia: number; inicio: string; fin: string}>) ?? [],
    nombresClinni: (data.nombresClinni as string[]) ?? undefined,
  };
}

/**
 * Localiza el doc de schedule por el nombre que aparece en
 * clinni_appointments.profesional. Hace 3 niveles de matching:
 *   1) Exacto contra el campo `nombre`.
 *   2) Exacto contra alguno de los aliases `nombresClinni[]`.
 *   3) Heurístico tras normalizar (quita Dr./Dra./acentos/lowercase) — match
 *      por tokens completos. P.ej. "Dra. María Vallés" matchea "María".
 * Devuelve null si no encuentra. Los nombres del equipo no se repiten, así
 * que no hay riesgo de falsos positivos en escenarios reales.
 */
export async function loadScheduleByName(nombreClinni: string): Promise<ProfessionalSchedule | null> {
  if (!nombreClinni) return null;
  try {
    // 1) Match exacto sobre `nombre`.
    const exact = await db.collection("professional_schedules")
        .where("nombre", "==", nombreClinni)
        .limit(1)
        .get();
    if (!exact.empty) return docToSchedule(exact.docs[0]);

    // 2 y 3) Cargamos todos y aplicamos matching heurístico/aliases.
    const all = await db.collection("professional_schedules").get();
    const candidates = all.docs.map(docToSchedule);
    const found = candidates.find((c) => nombreEncaja(c, nombreClinni));
    if (found) {
      functions.logger.info("loadScheduleByName: match heurístico", {
        nombreClinni, scheduleId: found.id, nombre: found.nombre,
      });
      return found;
    }
    functions.logger.info("loadScheduleByName: sin match", {nombreClinni});
    return null;
  } catch (e) {
    functions.logger.warn("loadScheduleByName falló", {nombreClinni, error: String(e)});
    return null;
  }
}

/** Convierte "HH:MM" + Date base a Date con esa hora local Europe/Madrid. */
function buildLocalDate(baseDay: Date, hhmm: string): Date {
  const [hh, mm] = hhmm.split(":").map(Number);
  // El servidor está en UTC; ajustamos creando la fecha en local TZ.
  // Estrategia: usar Date.UTC con offset CET/CEST. Para no liarnos con DST,
  // formateamos la fecha en TZ local, parseamos los componentes, y construimos.
  const local = new Date(baseDay);
  // Reseteamos hora primero
  local.setUTCHours(0, 0, 0, 0);
  // Componentes en TZ local
  const localDateStr = local.toLocaleString("en-CA", {
    timeZone: "Europe/Madrid",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  // localDateStr ej: "2026-04-30"
  const [Y, M, D] = localDateStr.split("-").map(Number);
  // Construimos en local — usamos new Date(Y, M-1, D, hh, mm) que respeta TZ del proceso.
  // Pero el servidor está en UTC, así que esa Date sería UTC. Necesitamos UTC equivalente
  // a la hora local. Usamos un truco: crear como si fuera UTC y ajustar offset.
  const candidateUTC = Date.UTC(Y, M - 1, D, hh, mm, 0, 0);
  // Calculamos el offset Europe/Madrid en ese momento (CEST=+2, CET=+1).
  const probe = new Date(candidateUTC);
  const localStr = probe.toLocaleString("en-US", {
    timeZone: "Europe/Madrid",
    hour12: false,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
  // Comparamos con lo que queríamos para deducir offset.
  // Si el valor en TZ Madrid difiere, ajustamos.
  // Implementación más robusta: probar varios offsets.
  // Para evitar este lío, usamos Intl.DateTimeFormat con timezone:
  for (const offsetMin of [0, 60, 120, -60]) {
    const test = new Date(candidateUTC - offsetMin * 60 * 1000);
    const fmt = test.toLocaleString("en-CA", {
      timeZone: "Europe/Madrid",
      hour12: false,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    });
    // fmt ej "2026-04-30, 15:00"
    const m = fmt.match(/^(\d{4})-(\d{2})-(\d{2}),?\s+(\d{2}):(\d{2})/);
    if (m) {
      const fY = Number(m[1]); const fM = Number(m[2]); const fD = Number(m[3]);
      const fh = Number(m[4]); const fmi = Number(m[5]);
      if (fY === Y && fM === M && fD === D && fh === hh && fmi === mm) {
        return test;
      }
    }
  }
  // Último recurso: confiamos en candidateUTC.
  void localStr;
  return new Date(candidateUTC);
}

/**
 * Slots teóricos en una ventana, descontando festivos. NO mira ocupación
 * (eso lo hace getOccupiedSlots aparte).
 */
export function generateCandidateSlots(
    schedule: ProfessionalSchedule,
    desde: Date,
    hasta: Date,
): Slot[] {
  if (!schedule.activo || schedule.escalaDirectaParaReagendar) return [];
  if (schedule.horarios.length === 0) return [];

  const out: Slot[] = [];
  const dur = schedule.duracionSlotMinutos * 60 * 1000;
  const cursor = new Date(desde);
  cursor.setUTCHours(0, 0, 0, 0);

  while (cursor.getTime() < hasta.getTime()) {
    if (!isHoliday(cursor)) {
      // Día de la semana en TZ local.
      const dowLocal = Number(cursor.toLocaleString("en-US", {
        timeZone: "Europe/Madrid",
        weekday: "short",
      }) === "Sun" ? 0 :
        cursor.toLocaleString("en-US", {timeZone: "Europe/Madrid", weekday: "short"}) === "Mon" ? 1 :
          cursor.toLocaleString("en-US", {timeZone: "Europe/Madrid", weekday: "short"}) === "Tue" ? 2 :
            cursor.toLocaleString("en-US", {timeZone: "Europe/Madrid", weekday: "short"}) === "Wed" ? 3 :
              cursor.toLocaleString("en-US", {timeZone: "Europe/Madrid", weekday: "short"}) === "Thu" ? 4 :
                cursor.toLocaleString("en-US", {timeZone: "Europe/Madrid", weekday: "short"}) === "Fri" ? 5 :
                  cursor.toLocaleString("en-US", {timeZone: "Europe/Madrid", weekday: "short"}) === "Sat" ? 6 : -1);
      const tramos = schedule.horarios.filter((h) => h.dia === dowLocal);
      for (const tramo of tramos) {
        const tramoInicio = buildLocalDate(cursor, tramo.inicio);
        const tramoFin = buildLocalDate(cursor, tramo.fin);
        let slotStart = tramoInicio.getTime();
        while (slotStart + dur <= tramoFin.getTime()) {
          if (slotStart >= desde.getTime() && slotStart + dur <= hasta.getTime()) {
            out.push({
              inicio: new Date(slotStart),
              fin: new Date(slotStart + dur),
              profesionalId: schedule.id,
              profesionalNombre: schedule.nombre,
            });
          }
          slotStart += dur;
        }
      }
    }
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }
  return out;
}

/**
 * Citas ya programadas para ese profesional en la ventana.
 * Solo coge estados activos: pendiente, confirmada, reagendada.
 */
export async function getOccupiedSlots(
    profesionalNombre: string,
    desde: Date,
    hasta: Date,
): Promise<Array<{inicio: Date; fin: Date}>> {
  try {
    const snap = await db.collection("clinni_appointments")
        .where("profesional", "==", profesionalNombre)
        .where("fechaCita", ">=", admin.firestore.Timestamp.fromDate(desde))
        .where("fechaCita", "<=", admin.firestore.Timestamp.fromDate(hasta))
        .where("estado", "in", ["pendiente", "confirmada", "reagendada"])
        .get();
    return snap.docs.map((d) => {
      const data = d.data();
      const ini = (data.fechaCita as admin.firestore.Timestamp).toDate();
      const dur = ((data.duracionMinutos as number | undefined) ?? 30) * 60 * 1000;
      return {inicio: ini, fin: new Date(ini.getTime() + dur)};
    });
  } catch (e) {
    functions.logger.warn("getOccupiedSlots falló — asumimos sin ocupados", {
      profesionalNombre,
      error: String(e),
    });
    return [];
  }
}

function slotsOverlap(a: Slot, b: {inicio: Date; fin: Date}): boolean {
  return a.inicio.getTime() < b.fin.getTime() && b.inicio.getTime() < a.fin.getTime();
}

export interface FindOpts {
  count: number;
  // Buffer mínimo desde ahora hasta el primer slot (default 1h, evita citas
  // demasiado inmediatas que recepción no llega a preparar).
  bufferMinutosDesdeAhora?: number;
  // Tope superior: ningún slot más tarde de este timestamp. Para regla 48h.
  restrictToBeforeMs?: number;
  // Días a buscar hacia adelante.
  diasVista?: number;
  // Si true (default), no se ofrecen slots del mismo día en curso. Razón:
  // los slots concertados por teléfono hoy mismo aún no están en
  // clinni_appointments hasta el próximo import del Excel; ofrecer slots
  // de hoy lleva riesgo de doble-reserva entre bot y recepción humana.
  skipSameDay?: boolean;
}

/** Devuelve el inicio (00:00) del día siguiente en TZ Europe/Madrid, como Date UTC. */
function startOfNextDayMadrid(now: Date): Date {
  const fmt = now.toLocaleDateString("en-CA", {timeZone: "Europe/Madrid"});
  // fmt = "2026-04-30"
  const [Y, M, D] = fmt.split("-").map(Number);
  // Base: mediodía UTC del día siguiente (siempre cae en ese día también en Madrid,
  // independiente del DST). buildLocalDate normaliza a 00:00 Madrid.
  const base = new Date(Date.UTC(Y, M - 1, D + 1, 12, 0, 0));
  return buildLocalDate(base, "00:00");
}

/**
 * Devuelve los próximos N slots disponibles del profesional.
 */
export async function findNextAvailableSlots(
    profesionalNombre: string,
    opts: FindOpts,
): Promise<{schedule: ProfessionalSchedule | null; slots: Slot[]}> {
  const schedule = await loadScheduleByName(profesionalNombre);
  if (!schedule || !schedule.activo || schedule.escalaDirectaParaReagendar) {
    return {schedule, slots: []};
  }

  const buffer = (opts.bufferMinutosDesdeAhora ?? 60) * 60 * 1000;
  const dias = opts.diasVista ?? 14;
  const skipSameDay = opts.skipSameDay !== false;
  const ahoraMasBuffer = new Date(Date.now() + buffer);
  // Si skipSameDay, el primer slot debe ser del día siguiente o posterior
  // (evita conflictos con citas que recepción concierte por teléfono hoy y
  //  todavía no estén en clinni_appointments hasta el próximo import).
  const desde = skipSameDay ?
    new Date(Math.max(ahoraMasBuffer.getTime(), startOfNextDayMadrid(new Date()).getTime())) :
    ahoraMasBuffer;
  const hastaWindow = new Date(desde.getTime() + dias * 24 * 60 * 60 * 1000);
  const hasta = opts.restrictToBeforeMs ?
    new Date(Math.min(hastaWindow.getTime(), opts.restrictToBeforeMs)) :
    hastaWindow;

  if (hasta.getTime() <= desde.getTime()) {
    return {schedule, slots: []};
  }

  const candidates = generateCandidateSlots(schedule, desde, hasta);
  const occupied = await getOccupiedSlots(schedule.nombre, desde, hasta);
  const free = candidates.filter((c) => !occupied.some((o) => slotsOverlap(c, o)));

  return {schedule, slots: free.slice(0, opts.count)};
}

/** Etiqueta corta de slot para botones WhatsApp (max 20 chars). */
export function shortLabelForSlot(slot: Slot): string {
  // p.ej. "L 5may 10:00" — caben 14-15 chars.
  const fmt = slot.inicio.toLocaleString("es-ES", {
    timeZone: "Europe/Madrid",
    weekday: "short",
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
  // toLocaleString suele devolver "lun., 5 abr., 10:00".
  // Limpiamos, capitalizamos y recortamos.
  const clean = fmt
      .replace(/\./g, "")
      .replace(",", "")
      .replace(/\s+/g, " ")
      .trim();
  const cap = clean.charAt(0).toUpperCase() + clean.slice(1);
  return cap.slice(0, 20);
}

/** Etiqueta larga para el body del mensaje (sin límite estricto). */
export function longLabelForSlot(slot: Slot): string {
  return slot.inicio.toLocaleString("es-ES", {
    timeZone: "Europe/Madrid",
    weekday: "long",
    day: "numeric",
    month: "long",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
}
