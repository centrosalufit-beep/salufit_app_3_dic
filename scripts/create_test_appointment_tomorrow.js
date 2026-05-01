/**
 * Crea una cita de TEST para mañana 01/05/2026 a las 18:00 ES, asociada
 * al teléfono 34667644475 (David Baydal). Sirve para validar el cron
 * sendAppointmentReminders + el template recordatorio_cita_v2 + los
 * botones interactivos en producción.
 *
 * El cron `sendAppointmentReminders` corre cada 30 min y busca citas
 * con fechaCita entre now+20h y now+48h. Una cita mañana a las 18:00
 * cae dentro de esa ventana, así que el bot enviará el recordatorio
 * en la próxima ejecución del cron (≤30 min después de crear esta cita).
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_appointment_tomorrow.js
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_appointment_tomorrow.js --delete
 */

const admin = require("firebase-admin");

const PROJECT_ID = "salufitnewapp";
const TELEFONO = "34667644475"; // David Baydal — paciente test
const APPOINTMENT_DOC_ID = "test_david_2may_18h";

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: PROJECT_ID,
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

async function main() {
  if (process.argv.includes("--delete")) {
    await db.collection("clinni_appointments").doc(APPOINTMENT_DOC_ID).delete();
    console.log(`✓ Borrado clinni_appointments/${APPOINTMENT_DOC_ID}`);
    process.exit(0);
  }

  // Asegurar que el paciente existe en clinni_patients (si no, el bot
  // lo trataría como "no registrado").
  const patientRef = db.collection("clinni_patients").doc(TELEFONO);
  const patientSnap = await patientRef.get();
  if (!patientSnap.exists) {
    await patientRef.set({
      numeroHistoria: "999999",
      nombreCompleto: "David Baydal",
      sexo: "H",
      dni: "",
      telefono: TELEFONO,
      email: "",
      fechaNacimiento: null,
      derivadoPor: "",
      etiquetas: ["test"],
      recibirMailing: false,
      proteccionDatosFirmada: true,
      infoSegundoTutor: "",
      origenExcel: "scripts/create_test_appointment_tomorrow.js",
      importadoEn: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`✓ Paciente clinni_patients/${TELEFONO} (David Baydal) creado`);
  } else {
    console.log(`✓ Paciente clinni_patients/${TELEFONO} ya existe (${patientSnap.data().nombreCompleto})`);
  }

  // Cita: sábado 2 mayo 2026, 18:00 ES (CEST = UTC+2 → 16:00 UTC).
  // ~21h en el futuro desde ahora (1/5 21:30) → entra en la ventana del
  // cron sendAppointmentReminders (now+20h a now+48h) en la próxima
  // ejecución (cada 30 min).
  const fechaCita = new Date(Date.UTC(2026, 4, 2, 16, 0, 0));
  await db.collection("clinni_appointments").doc(APPOINTMENT_DOC_ID).set({
    pacienteNombre: "David Baydal",
    pacienteTelefono: TELEFONO,
    fechaCita: admin.firestore.Timestamp.fromDate(fechaCita),
    profesional: "Ibtissam",
    servicio: "Fisioterapia",
    estado: "pendiente",
    duracionMinutos: 30,
    recordatorioEnviado: false,
    creadoPor: "scripts/create_test_appointment_tomorrow.js",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    notasTest: "Test E2E recordatorio template Meta + slots Opción B + flujo completo.",
  });
  console.log(`\n✓ Cita test creada en clinni_appointments/${APPOINTMENT_DOC_ID}`);
  console.log(`   fechaCita: ${fechaCita.toISOString()}`);
  console.log(`   local: ${fechaCita.toLocaleString("es-ES", {timeZone: "Europe/Madrid"})}`);
  console.log(`   profesional: Ibtissam (fisio)`);
  console.log(`   teléfono: ${TELEFONO}`);
  console.log(`\n⏰ El cron sendAppointmentReminders corre cada 30 min.`);
  console.log(`   El recordatorio debería llegar al WhatsApp de David en ≤30 min.`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
