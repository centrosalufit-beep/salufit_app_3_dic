/**
 * Festivos para Calpe (Alicante, Comunidad Valenciana).
 *
 * Combina:
 *   - Festivos nacionales españoles 2026 (BOE-A-2025-21667).
 *   - Festivos autonómicos Comunidad Valenciana 2026.
 *   - Festivos locales Calpe 2026.
 *
 * Para 2027 hay que actualizar este archivo cuando salga el BOE
 * (octubre 2026 aprox). Mientras, las funciones devuelven false para
 * fechas de 2027+ — el bot las trata como laborables. Si una de esas
 * fechas resulta ser festivo real, recepción lo gestionará manualmente
 * mediante la colección clinic_holidays (ver módulo de ausencias).
 *
 * Las fechas se almacenan en formato "YYYY-MM-DD" (TZ Europe/Madrid).
 */

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

/**
 * Devuelve la fecha como "YYYY-MM-DD" en zona horaria Europe/Madrid.
 */
function toLocalDateString(d: Date): string {
  // toLocaleString con "sv-SE" da "YYYY-MM-DD HH:MM:SS"; cogemos la fecha.
  return d.toLocaleString("sv-SE", {timeZone: "Europe/Madrid"}).slice(0, 10);
}

/**
 * Devuelve true si la fecha es festivo (nacional/autonómico/local) en Calpe.
 * Para fechas de años no soportados (2027+), devuelve false; recepción
 * gestionará vía clinic_holidays.
 */
export function isHoliday(date: Date): boolean {
  return HOLIDAY_SET.has(toLocalDateString(date));
}

/**
 * Lista pública por si el panel admin la quiere mostrar.
 */
export function getHolidays(year: 2026): ReadonlyArray<string> {
  if (year === 2026) return HOLIDAYS_2026;
  return [];
}
