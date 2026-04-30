/**
 * Diagnóstico rápido: lista las citas de un teléfono concreto en
 * clinni_appointments, sin filtros, para entender por qué el bot
 * no las encuentra.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/inspect_appointments.js [telefono]
 */

const admin = require("firebase-admin");

const TELEFONO = process.argv[2] || "34667644475";
const PROJECT_ID = "salufitnewapp";

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: PROJECT_ID,
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

async function main() {
  console.log(`\nBuscando citas de pacienteTelefono="${TELEFONO}" en clinni_appointments...\n`);

  const snap = await db.collection("clinni_appointments")
      .where("pacienteTelefono", "==", TELEFONO)
      .get();

  if (snap.empty) {
    console.log("  (sin resultados con ese teléfono exacto)");
    console.log("\nProbando variantes de formato...");
    const variantes = [
      `+${TELEFONO}`,
      TELEFONO.replace(/^34/, "+34"),
      TELEFONO.startsWith("+34") ? TELEFONO.slice(3) : `+34${TELEFONO}`,
    ];
    for (const v of variantes) {
      const s = await db.collection("clinni_appointments")
          .where("pacienteTelefono", "==", v)
          .get();
      if (!s.empty) {
        console.log(`  Encontrado con formato "${v}":`);
        s.docs.forEach((d) => {
          const data = d.data();
          console.log(`    - ${d.id}: ${data.pacienteNombre} | ${data.fechaCita?.toDate?.().toISOString()} | estado=${data.estado} | profesional=${data.profesional}`);
        });
      }
    }
    console.log("\nTotal de docs en clinni_appointments:");
    const allSnap = await db.collection("clinni_appointments").limit(1).get();
    if (allSnap.empty) {
      console.log("  Colección VACÍA — no hay ninguna cita importada todavía.");
    } else {
      const countSnap = await db.collection("clinni_appointments").count().get();
      console.log(`  ${countSnap.data().count} docs total.`);
      const sampleSnap = await db.collection("clinni_appointments").limit(3).get();
      console.log("  Sample de 3 docs (para ver formato esperado):");
      sampleSnap.docs.forEach((d) => {
        const data = d.data();
        console.log(`    - ${d.id}: nombre="${data.pacienteNombre}" tel="${data.pacienteTelefono}" fecha=${data.fechaCita?.toDate?.().toISOString()} estado=${data.estado} prof="${data.profesional}"`);
      });
    }
    process.exit(0);
  }

  console.log(`  ${snap.size} cita(s) encontrada(s):\n`);
  snap.docs.forEach((d) => {
    const data = d.data();
    const fecha = data.fechaCita?.toDate?.().toISOString();
    const ahora = new Date().toISOString();
    const futura = fecha && fecha >= ahora;
    console.log(`  - ${d.id}`);
    console.log(`      paciente: ${data.pacienteNombre}`);
    console.log(`      tel: ${data.pacienteTelefono}`);
    console.log(`      fecha: ${fecha} ${futura ? "(futura)" : "(PASADA)"}`);
    console.log(`      estado: ${data.estado}`);
    console.log(`      profesional: ${data.profesional}`);
    console.log(`      servicio: ${data.servicio ?? "-"}`);
  });
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
