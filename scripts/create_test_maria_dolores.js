/**
 * Test E2E del template recordatorio_cita_v2 con paciente que NUNCA ha
 * escrito al bot. Si el recordatorio llega → Fase 8 validada al 100%.
 *
 *   Paciente: María Dolores +34654445125
 *   Cita: sábado 2 mayo 2026 09:00 ES con Ibtissam (Fisioterapia)
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_maria_dolores.js
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_maria_dolores.js --delete
 */

const admin = require("firebase-admin");

const PROJECT_ID = "salufitnewapp";
const TELEFONO = "34654445125";
const APPOINTMENT_DOC_ID = "test_maria_dolores_t24h";

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
    await db.collection("clinni_patients").doc(TELEFONO).delete();
    console.log(`✓ Borrados clinni_appointments/${APPOINTMENT_DOC_ID} y clinni_patients/${TELEFONO}`);
    process.exit(0);
  }

  await db.collection("clinni_patients").doc(TELEFONO).set({
    numeroHistoria: "999997",
    nombreCompleto: "María Dolores",
    sexo: "F",
    dni: "",
    telefono: TELEFONO,
    email: "",
    fechaNacimiento: null,
    derivadoPor: "",
    etiquetas: ["test"],
    recibirMailing: false,
    proteccionDatosFirmada: true,
    infoSegundoTutor: "",
    origenExcel: "scripts/create_test_maria_dolores.js",
    importadoEn: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`✓ Paciente clinni_patients/${TELEFONO} (María Dolores)`);

  // Sábado 2 mayo 2026 09:00 ES (CEST = UTC+2 → 07:00 UTC).
  const fechaCita = new Date(Date.UTC(2026, 4, 2, 7, 0, 0));
  await db.collection("clinni_appointments").doc(APPOINTMENT_DOC_ID).set({
    pacienteNombre: "María Dolores",
    pacienteTelefono: TELEFONO,
    fechaCita: admin.firestore.Timestamp.fromDate(fechaCita),
    profesional: "Ibtissam",
    servicio: "Fisioterapia",
    estado: "pendiente",
    duracionMinutos: 30,
    recordatorioEnviado: false,
    creadoPor: "scripts/create_test_maria_dolores.js",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    notasTest: "Test E2E template Meta — paciente sin pre-contacto.",
  });
  console.log(`✓ Cita clinni_appointments/${APPOINTMENT_DOC_ID}`);
  console.log(`  fechaCita: ${fechaCita.toISOString()} (${fechaCita.toLocaleString("es-ES", {timeZone: "Europe/Madrid"})})`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
