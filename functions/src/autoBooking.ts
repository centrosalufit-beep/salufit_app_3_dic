/**
 * Auto-cita para leads (Fase E).
 *
 * Cuando un lead completa el onboarding, intentamos ofrecerle slots
 * reales del profesional que mapea con su `servicioInteres`. Si el
 * paciente pulsa un slot, lo dejamos en `clinni_appointments_pending`
 * para que recepción valide y mueva a `clinni_appointments`/Clinni.
 *
 * Mapping servicio → profesional por defecto. Si recepción quiere
 * cambiar (p.ej. asignar a Álvaro en vez de Ibtissam), edita en panel.
 * Si el servicio no mapea a un profesional, NO se ofrecen slots y el
 * lead queda solo en la bandeja de validación.
 */

import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

/**
 * Mapping heurístico servicio (texto libre del paciente) → nombre del
 * profesional principal en `professional_schedules`. Devuelve null si no
 * encuentra match — caller debe escalar a recepción.
 */
export function mapServicioToProfesional(servicio: string): string | null {
  const s = servicio.toLowerCase().trim();
  // Fisioterapia: derivar a Ibtissam por defecto (también trabaja sábados).
  if (s.includes("fisio") || s.includes("physio")) return "Ibtissam";
  // Psicología.
  if (s.includes("psico") || s.includes("psych")) return "Noelia";
  // Odontología — escalada directa siempre (no auto-cita).
  if (s.includes("dental") || s.includes("dentist") ||
      s.includes("odonto") || s.includes("dientes") ||
      s.includes("muela")) return null;
  // Podología.
  if (s.includes("podo")) return null; // sin schedule activo aún
  return null;
}

/**
 * Persiste una cita pendiente de validación en
 * `clinni_appointments_pending`. Recepción la aprueba (la copia a
 * `clinni_appointments` + Clinni manual) o la rechaza.
 */
export async function persistPendingAppointment(params: {
  pacienteNombre: string;
  pacienteTelefono: string;
  fechaCita: Date;
  profesional: string;
  servicio: string;
  conversationId: string;
  origen: "lead_nuevo" | "paciente_existente";
}): Promise<string> {
  const ref = await db.collection("clinni_appointments_pending").add({
    pacienteNombre: params.pacienteNombre,
    pacienteTelefono: params.pacienteTelefono,
    fechaCita: admin.firestore.Timestamp.fromDate(params.fechaCita),
    profesional: params.profesional,
    servicio: params.servicio,
    estado: "pendiente_validacion",
    conversationId: params.conversationId,
    origen: params.origen,
    creadoEn: admin.firestore.FieldValue.serverTimestamp(),
  });
  return ref.id;
}
