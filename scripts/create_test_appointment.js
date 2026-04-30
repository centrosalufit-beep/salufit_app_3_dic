/**
 * Crea citas de test en clinni_appointments para validar el bot.
 *
 * Presets:
 *   default → test_david_fase2: lunes 4 mayo 2026, 11:00 ES (Fase 2 reagendar
 *     con cita >48h vista, no aplica restricción 48h).
 *   --t24h  → test_david_t24h:  +24h desde ahora (recordatorio T-24h y test
 *     de política 48h cuando el paciente cancele/reagende).
 *
 * Acciones:
 *   default → set (crea o sobrescribe).
 *   --delete → borra el doc del preset elegido.
 *   --delete-all → borra ambos.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_appointment.js
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_appointment.js --t24h
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_appointment.js --delete
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_appointment.js --t24h --delete
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/create_test_appointment.js --delete-all
 */

const admin = require("firebase-admin");

const PROJECT_ID = "salufitnewapp";

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: PROJECT_ID,
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

const argv = process.argv.slice(2);
const isT24h = argv.includes("--t24h");
const isDelete = argv.includes("--delete");
const isDeleteAll = argv.includes("--delete-all");

const PRESETS = {
  fase2: {
    docId: "test_david_fase2",
    // Lunes 4 mayo 2026, 11:00 Europe/Madrid (CEST=UTC+2) → 09:00 UTC.
    fechaCita: new Date(Date.UTC(2026, 4, 4, 9, 0, 0)),
    notas: "Cita generada para validar Fase 2 (reagendación automática, >48h vista).",
  },
  t24h: {
    docId: "test_david_t24h",
    // 24h desde ahora redondeado al próximo cuarto de hora (>20h y <48h vista
    // para entrar en la ventana del cron sendAppointmentReminders).
    fechaCita: (() => {
      const d = new Date(Date.now() + 24 * 60 * 60 * 1000);
      d.setMinutes(0, 0, 0);
      return d;
    })(),
    notas: "Cita generada para validar recordatorio T-24h y política 48h.",
  },
};

async function deletePreset(preset) {
  const ref = db.collection("clinni_appointments").doc(preset.docId);
  await ref.delete();
  console.log(`✓ Borrado clinni_appointments/${preset.docId}`);
}

async function setPreset(preset) {
  const ref = db.collection("clinni_appointments").doc(preset.docId);
  const data = {
    pacienteNombre: "David Baydal",
    pacienteTelefono: "34667644475",
    fechaCita: admin.firestore.Timestamp.fromDate(preset.fechaCita),
    profesional: "David",
    servicio: "Fisioterapia",
    estado: "pendiente",
    duracionMinutos: 30,
    recordatorioEnviado: false,
    creadoPor: "scripts/create_test_appointment.js",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    notasTest: preset.notas,
  };
  await ref.set(data);
  console.log(`✓ Creado clinni_appointments/${preset.docId}`);
  console.log(`  paciente   : ${data.pacienteNombre} (${data.pacienteTelefono})`);
  console.log(
      `  fechaCita  : ${preset.fechaCita.toISOString()} ` +
      `(${preset.fechaCita.toLocaleString("es-ES", {timeZone: "Europe/Madrid"})})`,
  );
  console.log(`  profesional: ${data.profesional}`);
  console.log(`  estado     : ${data.estado}`);
}

async function main() {
  if (isDeleteAll) {
    await deletePreset(PRESETS.fase2);
    await deletePreset(PRESETS.t24h);
    process.exit(0);
  }
  const preset = isT24h ? PRESETS.t24h : PRESETS.fase2;
  if (isDelete) {
    await deletePreset(preset);
  } else {
    await setPreset(preset);
  }
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
