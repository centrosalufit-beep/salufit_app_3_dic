/**
 * Diagnóstico rápido del estado de las colecciones del bot WhatsApp.
 * Cuenta docs y muestra sample en clinni_patients, clinni_appointments,
 * whatsapp_conversations.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/inspect_collections.js
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

async function inspectCollection(name, sampleSize = 2) {
  try {
    const countSnap = await db.collection(name).count().get();
    const total = countSnap.data().count;
    console.log(`\n📂 ${name}: ${total} docs`);
    if (total > 0) {
      const sample = await db.collection(name).limit(sampleSize).get();
      console.log(`   Sample (${sample.size} docs):`);
      sample.docs.forEach((d, i) => {
        const data = d.data();
        const keys = Object.keys(data).slice(0, 6).join(", ");
        console.log(`     ${i + 1}. ${d.id} - keys: [${keys}]`);
      });
    }
  } catch (e) {
    console.log(`\n❌ ${name}: error - ${e.message}`);
  }
}

async function main() {
  console.log("Inspeccionando colecciones del bot WhatsApp...\n");

  await inspectCollection("clinni_patients");
  await inspectCollection("clinni_appointments");
  await inspectCollection("whatsapp_conversations", 1);
  await inspectCollection("professional_schedules", 1);
  await inspectCollection("whatsapp_processed_messages", 1);
  await inspectCollection("whatsapp_rate_limit", 1);
  await inspectCollection("whatsapp_optouts", 1);

  // Citas test específicas
  console.log("\n📋 Citas de test (David Baydal +34667644475):");
  const testSnap = await db.collection("clinni_appointments")
      .where("pacienteTelefono", "==", "34667644475")
      .get();
  console.log(`   Total con tel 34667644475: ${testSnap.size}`);
  testSnap.docs.forEach((d) => {
    const data = d.data();
    const fecha = data.fechaCita?.toDate?.().toISOString();
    console.log(`     - ${d.id}: ${fecha} estado=${data.estado} prof=${data.profesional} recordatorio=${data.recordatorioEnviado}`);
  });

  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
