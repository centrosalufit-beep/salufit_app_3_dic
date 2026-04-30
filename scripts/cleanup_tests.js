/**
 * Limpieza de citas, pacientes y conversaciones de test acumuladas durante
 * el desarrollo. Por defecto hace DRY-RUN (lista lo que borraría sin tocar
 * nada). Pasar --execute para borrar de verdad.
 *
 * Borra:
 *   - clinni_appointments con creadoPor que empieza por "scripts/"
 *     (test_david_fase2, test_david_t24h, test_maria_t24h,
 *      test_maria_dolores_t24h).
 *   - clinni_patients de los teléfonos de test (María TEST, María Dolores).
 *   - whatsapp_conversations cuyos pacienteTelefono sean números test
 *     (34667644475 = David Baydal, 34628180715 = María TEST,
 *      34654445125 = María Dolores).
 *   - whatsapp_processed_messages (todos los message_id de >24h ya no
 *     hacen falta para idempotencia).
 *   - whatsapp_rate_limit (limpieza de timestamps viejos).
 *
 * NO borra:
 *   - clinni_patients reales del listado_v26 (4786 docs).
 *   - clinni_appointments reales sin creadoPor de scripts.
 *   - audit_logs (queremos la trazabilidad).
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/cleanup_tests.js
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/cleanup_tests.js --execute
 */

const admin = require("firebase-admin");

const PROJECT_ID = "salufitnewapp";
const TEST_PATIENT_PHONES = ["34667644475", "34628180715", "34654445125"];
const TEST_APPOINTMENT_IDS = [
  "test_david_fase2",
  "test_david_t24h",
  "test_maria_t24h",
  "test_maria_dolores_t24h",
];

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: PROJECT_ID,
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

const EXECUTE = process.argv.includes("--execute");
console.log(`Modo: ${EXECUTE ? "🔴 EXECUTE — borrará de verdad" : "🟡 DRY-RUN — solo lista"}\n`);

async function deleteIfExecute(ref, label) {
  console.log(`  - ${label}`);
  if (EXECUTE) await ref.delete();
}

async function deleteCollection(query, label) {
  const snap = await query.get();
  console.log(`\n📂 ${label}: ${snap.size} docs`);
  for (const doc of snap.docs) {
    await deleteIfExecute(doc.ref, doc.id);
  }
  return snap.size;
}

async function main() {
  // 1) Citas test por id
  console.log("📂 Citas test (clinni_appointments) por ID:");
  for (const id of TEST_APPOINTMENT_IDS) {
    const ref = db.collection("clinni_appointments").doc(id);
    const snap = await ref.get();
    if (snap.exists) {
      console.log(`  - ${id}: ${snap.data().pacienteNombre} ${snap.data().fechaCita?.toDate?.().toISOString()}`);
      if (EXECUTE) await ref.delete();
    } else {
      console.log(`  - ${id}: (no existe)`);
    }
  }

  // 2) Citas con creadoPor de scripts (catch-all por si quedó alguna)
  await deleteCollection(
      db.collection("clinni_appointments").where("creadoPor", ">=", "scripts/").where("creadoPor", "<", "scripts0"),
      "clinni_appointments con creadoPor=scripts/*",
  );

  // 3) Pacientes test (NO borra los 4786 de listado_v26)
  console.log("\n📂 Pacientes test (clinni_patients):");
  for (const tel of TEST_PATIENT_PHONES) {
    const ref = db.collection("clinni_patients").doc(tel);
    const snap = await ref.get();
    if (snap.exists) {
      const data = snap.data();
      const isTest = (data.origenExcel ?? "").startsWith("scripts/") ||
        (data.etiquetas ?? []).includes("test");
      if (isTest) {
        console.log(`  - ${tel}: ${data.nombreCompleto} (test=${isTest})`);
        if (EXECUTE) await ref.delete();
      } else {
        console.log(`  - ${tel}: ${data.nombreCompleto} ⚠️ NO-TEST (origenExcel=${data.origenExcel}) — NO se borra por seguridad`);
      }
    } else {
      console.log(`  - ${tel}: (no existe)`);
    }
  }

  // 4) Conversaciones de teléfonos test
  for (const tel of TEST_PATIENT_PHONES) {
    await deleteCollection(
        db.collection("whatsapp_conversations").where("pacienteTelefono", "==", tel),
        `whatsapp_conversations de ${tel}`,
    );
  }

  // 5) whatsapp_processed_messages (idempotencia, 24h+ ya no sirven)
  await deleteCollection(
      db.collection("whatsapp_processed_messages"),
      "whatsapp_processed_messages (todos)",
  );

  // 6) whatsapp_rate_limit (todos)
  await deleteCollection(
      db.collection("whatsapp_rate_limit"),
      "whatsapp_rate_limit (todos)",
  );

  console.log(`\n${EXECUTE ? "✅ Limpieza ejecutada." : "🟡 Dry-run terminado. Re-ejecuta con --execute para borrar de verdad."}`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
