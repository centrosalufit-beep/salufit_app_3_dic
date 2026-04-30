/**
 * Crea una cita de test en clinni_appointments para validar la Fase 2.
 *
 * Datos:
 *   - pacienteTelefono: 34667644475 (David Baydal)
 *   - fechaCita: lunes 4 mayo 2026, 11:00 hora España (09:00 UTC en CEST)
 *   - profesional: "David" (fisio activo en professional_schedules)
 *   - servicio: "Fisioterapia"
 *   - estado: "pendiente"
 *
 * Doc id: test_david_fase2 (idempotente, sobrescribe si ya existe).
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_appointment.js
 *
 * Para borrar el doc después:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_appointment.js --delete
 */

const admin = require("firebase-admin");

const PROJECT_ID = "salufitnewapp";
const DOC_ID = "test_david_fase2";

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: PROJECT_ID,
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

async function main() {
  const ref = db.collection("clinni_appointments").doc(DOC_ID);

  if (process.argv.includes("--delete")) {
    await ref.delete();
    console.log(`✓ Borrado clinni_appointments/${DOC_ID}`);
    return;
  }

  // Lunes 4 mayo 2026, 11:00 hora Europe/Madrid (CEST = UTC+2) → 09:00 UTC.
  const fechaCita = new Date(Date.UTC(2026, 4, 4, 9, 0, 0)); // mes 4 = mayo (0-indexed)

  const data = {
    pacienteNombre: "David Baydal",
    pacienteTelefono: "34667644475",
    fechaCita: admin.firestore.Timestamp.fromDate(fechaCita),
    profesional: "David",
    servicio: "Fisioterapia",
    estado: "pendiente",
    duracionMinutos: 30,
    recordatorioEnviado: false,
    creadoPor: "scripts/create_test_appointment.js",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    notasTest: "Cita generada para validar Fase 2 (reagendación automática). Borrar tras el test.",
  };

  await ref.set(data);
  console.log(`✓ Creado clinni_appointments/${DOC_ID}`);
  console.log(`  paciente   : ${data.pacienteNombre} (${data.pacienteTelefono})`);
  console.log(`  fechaCita  : ${fechaCita.toISOString()} (${fechaCita.toLocaleString("es-ES", {timeZone: "Europe/Madrid"})})`);
  console.log(`  profesional: ${data.profesional}`);
  console.log(`  estado     : ${data.estado}`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
