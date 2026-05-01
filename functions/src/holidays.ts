/**
 * Festivos para Calpe (Alicante, Comunidad Valenciana).
 *
 * Fuente prioritaria: colección `clinic_holidays` en Firestore (editable
 * desde el panel admin). Fallback: lista hardcoded de festivos 2026 si
 * Firestore no devuelve datos para esa fecha.
 *
 * Para integración con `slots.ts`, exponemos `isHolidayAsync(date)` que
 * combina ambas fuentes. La función legacy `isHoliday(date)` (síncrona)
 * sigue disponible para callers que no puedan ser async, pero solo mira
 * el set hardcoded.
 *
 * Las fechas se almacenan en formato "YYYY-MM-DD" (TZ Europe/Madrid).
 */

import {loadUpcomingHolidays} from "./clinicInfo";

const HOLIDAYS_2026: ReadonlyArray<string> = [
  "2026-01-01", // Año Nuevo
  "2026-01-06", // Reyes
  "2026-03-19", // San José (auton. CV)
  "2026-04-03", // Viernes Santo
  "2026-04-06", // Lunes de Pascua (auton. CV)
  "2026-05-01", // Día del Trabajo
  "2026-06-24", // Sant Joan (auton. CV)
  "2026-08-05", // Madre de Dios de las Nieves (local Calpe)
  "2026-08-15", // Asunción
  "2026-10-09", // Día Comunidad Valenciana
  "2026-10-12", // Fiesta Nacional de España
  "2026-10-22", // Santísimo Cristo del Sudor (local Calpe)
  "2026-12-08", // Inmaculada
  "2026-12-25", // Navidad
];

const HOLIDAY_SET = new Set<string>(HOLIDAYS_2026);

function toLocalDateString(d: Date): string {
  return d.toLocaleString("sv-SE", {timeZone: "Europe/Madrid"}).slice(0, 10);
}

/**
 * Versión síncrona — solo mira el set hardcoded. Usada por callers
 * legacy que no pueden ser async.
 */
export function isHoliday(date: Date): boolean {
  return HOLIDAY_SET.has(toLocalDateString(date));
}

/**
 * Versión recomendada: combina Firestore (clinic_holidays editable) con
 * el hardcoded fallback. Si Firestore tiene un festivo o cierre
 * excepcional para esa fecha, devuelve true. Si no, cae al hardcoded.
 *
 * NOTA: tipo "horario_reducido" NO cuenta como cerrado — el centro abre,
 * solo con horario distinto. Eso lo gestiona el resto del flujo.
 */
export async function isHolidayAsync(date: Date): Promise<boolean> {
  const iso = toLocalDateString(date);
  if (HOLIDAY_SET.has(iso)) return true;
  const dynamic = await loadUpcomingHolidays();
  return dynamic.some((h) =>
    h.fecha === iso &&
    (h.tipo === "festivo" || h.tipo === "cerrado_excepcional"),
  );
}

export function getHolidays(year: 2026): ReadonlyArray<string> {
  if (year === 2026) return HOLIDAYS_2026;
  return [];
}
