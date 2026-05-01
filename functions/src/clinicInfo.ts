/**
 * Centro de información dinámico — Fase A.
 *
 * Lee el doc `config/clinic_info` y las colecciones `clinic_holidays` y
 * `professional_absences` desde Firestore con caché en memoria del proceso
 * (5 min TTL) para evitar costes de lectura por cada mensaje del bot.
 *
 * El cliente (Flutter panel admin) escribe estos datos; este módulo los
 * lee para inyectarlos al system prompt de Claude y al generador de slots.
 */

import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

export interface DayHours {
  abre: string; // "HH:MM" 24h
  cierra: string;
}

export interface ServicioInfo {
  nombre: string;
  precio?: number; // en euros, opcional (algunos servicios no son públicos)
  descripcion?: string;
}

export interface ClinicInfo {
  horarios: {
    lunes: DayHours | null;
    martes: DayHours | null;
    miercoles: DayHours | null;
    jueves: DayHours | null;
    viernes: DayHours | null;
    sabado: DayHours | null;
    domingo: DayHours | null;
  };
  direccion: string;
  googleMapsUrl: string;
  telefonoRecepcion: string;
  parking: string;
  comoLlegar: string;
  primeraVisita: string;
  servicios: ServicioInfo[];
  bienvenidaNuevoPaciente: string;
}

export interface Holiday {
  fecha: string; // ISO YYYY-MM-DD
  motivo: string;
  tipo: "festivo" | "cerrado_excepcional" | "horario_reducido";
  // Solo aplicable si tipo === "horario_reducido"
  horarioEspecial?: DayHours;
}

export interface ProfessionalAbsence {
  profesionalId: string; // doc ID en professional_schedules
  desde: admin.firestore.Timestamp;
  hasta: admin.firestore.Timestamp;
  motivo: string; // "vacaciones", "baja", "formación", etc.
}

export const DEFAULT_CLINIC_INFO: ClinicInfo = {
  horarios: {
    lunes: {abre: "09:00", cierra: "20:00"},
    martes: {abre: "09:00", cierra: "20:00"},
    miercoles: {abre: "09:00", cierra: "20:00"},
    jueves: {abre: "09:00", cierra: "20:00"},
    viernes: {abre: "09:00", cierra: "20:00"},
    sabado: {abre: "09:00", cierra: "13:00"},
    domingo: null,
  },
  direccion: "",
  googleMapsUrl: "",
  telefonoRecepcion: "+34 629 01 10 55",
  parking: "",
  comoLlegar: "",
  primeraVisita: "",
  servicios: [],
  bienvenidaNuevoPaciente:
    "¡Hola! 👋 Te escribe el bot del Centro Salufit. " +
    "Cuéntame en qué puedo ayudarte.",
};

const CACHE_TTL_MS = 5 * 60 * 1000;

interface CacheEntry<T> {
  data: T;
  expiresAt: number;
}

let infoCache: CacheEntry<ClinicInfo> | null = null;
let holidaysCache: CacheEntry<Holiday[]> | null = null;
let absencesCache: CacheEntry<ProfessionalAbsence[]> | null = null;

export function invalidateClinicCache(): void {
  infoCache = null;
  holidaysCache = null;
  absencesCache = null;
}

/**
 * Carga `config/clinic_info`. Si no existe, devuelve los defaults.
 */
export async function loadClinicInfo(): Promise<ClinicInfo> {
  if (infoCache && infoCache.expiresAt > Date.now()) return infoCache.data;
  try {
    const doc = await db.collection("config").doc("clinic_info").get();
    const raw = (doc.data() ?? {}) as Partial<ClinicInfo>;
    const data: ClinicInfo = {
      horarios: raw.horarios ?? DEFAULT_CLINIC_INFO.horarios,
      direccion: raw.direccion ?? "",
      googleMapsUrl: raw.googleMapsUrl ?? "",
      telefonoRecepcion: raw.telefonoRecepcion ??
        DEFAULT_CLINIC_INFO.telefonoRecepcion,
      parking: raw.parking ?? "",
      comoLlegar: raw.comoLlegar ?? "",
      primeraVisita: raw.primeraVisita ?? "",
      servicios: Array.isArray(raw.servicios) ? raw.servicios : [],
      bienvenidaNuevoPaciente: raw.bienvenidaNuevoPaciente ??
        DEFAULT_CLINIC_INFO.bienvenidaNuevoPaciente,
    };
    infoCache = {data, expiresAt: Date.now() + CACHE_TTL_MS};
    return data;
  } catch {
    return DEFAULT_CLINIC_INFO;
  }
}

/**
 * Carga todos los `clinic_holidays` desde hoy en adelante (12 meses).
 * Útil para el bot (responder "¿abrís el 5 agosto?") y para slots.ts.
 */
export async function loadUpcomingHolidays(): Promise<Holiday[]> {
  if (holidaysCache && holidaysCache.expiresAt > Date.now()) {
    return holidaysCache.data;
  }
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayIso = today.toISOString().slice(0, 10);
    const limit = new Date(today.getTime() + 365 * 86400000);
    const limitIso = limit.toISOString().slice(0, 10);

    const snap = await db.collection("clinic_holidays")
        .where("fecha", ">=", todayIso)
        .where("fecha", "<=", limitIso)
        .orderBy("fecha")
        .get();
    const data: Holiday[] = snap.docs.map((d) => {
      const r = d.data();
      return {
        fecha: String(r.fecha ?? ""),
        motivo: String(r.motivo ?? ""),
        tipo: (r.tipo as Holiday["tipo"]) ?? "festivo",
        horarioEspecial: r.horarioEspecial as DayHours | undefined,
      };
    });
    holidaysCache = {data, expiresAt: Date.now() + CACHE_TTL_MS};
    return data;
  } catch {
    return [];
  }
}

/**
 * Indica si una fecha (timezone Europe/Madrid) cae en festivo o
 * cerrado excepcional. NO incluye horarios reducidos (esos siguen
 * abriendo, solo con horario distinto).
 */
export async function isClinicClosedOn(date: Date): Promise<{
  closed: boolean;
  motivo?: string;
  tipo?: Holiday["tipo"];
}> {
  const iso = date.toLocaleDateString("sv-SE", {timeZone: "Europe/Madrid"});
  const holidays = await loadUpcomingHolidays();
  const match = holidays.find((h) => h.fecha === iso);
  if (!match) return {closed: false};
  if (match.tipo === "festivo" || match.tipo === "cerrado_excepcional") {
    return {closed: true, motivo: match.motivo, tipo: match.tipo};
  }
  return {closed: false, motivo: match.motivo, tipo: match.tipo};
}

/**
 * Carga ausencias activas y futuras de profesionales.
 */
export async function loadActiveAbsences(): Promise<ProfessionalAbsence[]> {
  if (absencesCache && absencesCache.expiresAt > Date.now()) {
    return absencesCache.data;
  }
  try {
    const now = admin.firestore.Timestamp.now();
    const snap = await db.collection("professional_absences")
        .where("hasta", ">=", now)
        .get();
    const data: ProfessionalAbsence[] = snap.docs.map((d) => {
      const r = d.data();
      return {
        profesionalId: String(r.profesionalId ?? ""),
        desde: r.desde as admin.firestore.Timestamp,
        hasta: r.hasta as admin.firestore.Timestamp,
        motivo: String(r.motivo ?? ""),
      };
    });
    absencesCache = {data, expiresAt: Date.now() + CACHE_TTL_MS};
    return data;
  } catch {
    return [];
  }
}

/**
 * Indica si un profesional está ausente en una fecha concreta.
 */
export async function isProfessionalAbsent(
    profesionalId: string,
    date: Date,
): Promise<{absent: boolean; motivo?: string}> {
  const absences = await loadActiveAbsences();
  const t = date.getTime();
  const match = absences.find((a) =>
    a.profesionalId === profesionalId &&
    a.desde.toDate().getTime() <= t &&
    a.hasta.toDate().getTime() >= t,
  );
  return match ? {absent: true, motivo: match.motivo} : {absent: false};
}

/**
 * Render del centro de información en formato compacto para inyectar al
 * system prompt de Claude. Mantenemos texto plano en español, sin
 * markdown, para que Claude lo cite literalmente cuando le pregunten.
 */
export function renderClinicInfoForPrompt(
    info: ClinicInfo,
    holidays: Holiday[],
): string {
  const lines: string[] = ["INFORMACIÓN DEL CENTRO (datos verídicos — úsalos como referencia, NO inventes):"];

  // Horarios
  lines.push("Horarios habituales:");
  const dias: Array<keyof ClinicInfo["horarios"]> = [
    "lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo",
  ];
  const diasLabel: Record<string, string> = {
    lunes: "Lunes", martes: "Martes", miercoles: "Miércoles",
    jueves: "Jueves", viernes: "Viernes", sabado: "Sábado",
    domingo: "Domingo",
  };
  for (const d of dias) {
    const h = info.horarios[d];
    lines.push(`  - ${diasLabel[d]}: ${h ? `${h.abre}–${h.cierra}` : "cerrado"}`);
  }

  if (info.direccion) lines.push(`Dirección: ${info.direccion}`);
  if (info.telefonoRecepcion) lines.push(`Teléfono de recepción: ${info.telefonoRecepcion}`);
  if (info.parking) lines.push(`Parking: ${info.parking}`);
  if (info.comoLlegar) lines.push(`Cómo llegar: ${info.comoLlegar}`);
  if (info.primeraVisita) lines.push(`Primera visita: ${info.primeraVisita}`);

  if (info.servicios.length > 0) {
    lines.push("Servicios:");
    for (const s of info.servicios) {
      const precio = s.precio ? ` — ${s.precio}€` : "";
      const desc = s.descripcion ? ` (${s.descripcion})` : "";
      lines.push(`  - ${s.nombre}${precio}${desc}`);
    }
  }

  // Festivos próximos (60 días) — limitado para no saturar el prompt
  const proximos = holidays.slice(0, 8);
  if (proximos.length > 0) {
    lines.push("Días cerrados próximos:");
    for (const h of proximos) {
      const tipoLabel = h.tipo === "horario_reducido" ?
        ` (horario reducido${h.horarioEspecial ? `: ${h.horarioEspecial.abre}-${h.horarioEspecial.cierra}` : ""})` :
        "";
      lines.push(`  - ${h.fecha}: ${h.motivo}${tipoLabel}`);
    }
  }

  return lines.join("\n");
}
