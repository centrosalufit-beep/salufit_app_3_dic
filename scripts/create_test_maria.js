/**
 * Crea cita ficticia + paciente para test de flujo end-to-end:
 *   - Paciente: María (test) +34628180715
 *   - Cita: viernes 1 mayo 2026 11:00 ES con David (fisioterapia)
 *
 * Importante: el viernes 1 mayo es festivo + el sábado/domingo David no
 * trabaja. Por tanto si pulsa "Cambiar cita" → 0 slots ofrecidos →
 * escala a recepción. Si pulsa "Cancelar" → política 48h → escala.
 * Si pulsa "Confirmar" → confirma.
 *
 * También crea/actualiza el doc en clinni_patients para que no entre en
 * filtro Fase 3. La paciente debe escribir "test" al bot ANTES (regla
 * ventana 24h Meta) si queremos que reciba mensajes.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_maria.js
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_maria.js --delete
 */

const admin = require("firebase-admin");

const PROJECT_ID = "salufitnewapp";
const TELEFONO = "34628180715";
const APPOINTMENT_DOC_ID = "test_maria_t24h";

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: PROJECT_ID,
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

async function main() {
  const isDelete = process.argv.includes("--delete");

  if (isDelete) {
    await db.collection("clinni_appointments").doc(APPOINTMENT_DOC_ID).delete();
    console.log(`✓ Borrada cita ${APPOINTMENT_DOC_ID}`);
    await db.collection("clinni_patients").doc(TELEFONO).delete();
    console.log(`✓ Borrado paciente ${TELEFONO}`);
    process.exit(0);
  }

  // 1) Paciente
  await db.collection("clinni_patients").doc(TELEFONO).set({
    numeroHistoria: "999998",
    nombreCompleto: "María (TEST)",
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
    origenExcel: "scripts/create_test_maria.js",
    importadoEn: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`✓ Paciente clinni_patients/${TELEFONO} (María TEST)`);

  // 2) Cita: sábado 2 mayo 2026 09:00 ES (07:00 UTC en CEST). Elegido para que:
  //    - La cita NO caiga en festivo (1 mayo) — viernes evitado.
  //    - Esté dentro de la ventana del cron (20-48h vista desde un jueves
  //      por la tarde / viernes por la mañana).
  //    - Ibtissam (fisio que trabaja S 8-12) tenga slots libres después
  //      del 09:00 dentro de las 48h SIGUIENTES a la cita (resto del sábado),
  //      para validar el flujo "Cancelar → ofrecer slots".
  const fechaCita = new Date(Date.UTC(2026, 4, 2, 7, 0, 0));
  await db.collection("clinni_appointments").doc(APPOINTMENT_DOC_ID).set({
    pacienteNombre: "María (TEST)",
    pacienteTelefono: TELEFONO,
    fechaCita: admin.firestore.Timestamp.fromDate(fechaCita),
    profesional: "Ibtissam",
    servicio: "Fisioterapia",
    estado: "pendiente",
    duracionMinutos: 30,
    recordatorioEnviado: false,
    creadoPor: "scripts/create_test_maria.js",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    notasTest: "Cita simulación María con Ibtissam sábado 2 mayo 09:00.",
  });
  console.log(`✓ Cita clinni_appointments/${APPOINTMENT_DOC_ID}`);
  console.log(`  fechaCita: ${fechaCita.toISOString()} (${fechaCita.toLocaleString("es-ES", {timeZone: "Europe/Madrid"})})`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
