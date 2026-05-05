/**
 * Resetea recordatorioEnviado=false para citas que recibieron un
 * recordatorio CON el bug de timezone (+2h). El cron las re-procesará
 * con la hora correcta tras la migración fix_citas_offset_2h.
 *
 * Solo aplica a citas:
 *   - origenExcel empieza por "informe_citas_" (importadas Clinni con bug)
 *   - recordatorioEnviado === true
 *   - estado === "pendiente" (no atendida ni cancelada)
 *   - fechaCita >= ahora (futuras)
 */
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "salufitnewapp",
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();
const EXECUTE = process.argv.includes("--execute");

async function main() {
  console.log(`Modo: ${EXECUTE ? "🔴 EXECUTE" : "🟡 DRY-RUN"}\n`);
  const now = admin.firestore.Timestamp.now();
  const snap = await db.collection("clinni_appointments")
      .where("recordatorioEnviado", "==", true)
      .where("estado", "==", "pendiente")
      .where("fechaCita", ">=", now)
      .get();

  console.log(`📊 Citas pendientes futuras con recordatorioEnviado=true: ${snap.size}\n`);

  let reset = 0;
  let skipped = 0;
  for (const doc of snap.docs) {
    const d = doc.data();
    const origen = d.origenExcel || "";
    if (!String(origen).startsWith("informe_citas_")) {
      skipped++;
      continue;
    }
    const f = d.fechaCita.toDate();
    console.log(`  ${EXECUTE ? "🔄" : "[dry]"} ${d.pacienteNombre.slice(0, 25).padEnd(25)} | ${f.toLocaleString("es-ES", {timeZone: "Europe/Madrid"})} | ${d.profesional}`);
    if (EXECUTE) {
      await doc.ref.update({
        recordatorioEnviado: false,
        fechaRecordatorio: null,
        reseteadaPorBugTimezone: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    reset++;
  }
  console.log(`\n${EXECUTE ? "✅ Reseteadas" : "Hubieran sido reseteadas"}: ${reset}`);
  console.log(`Saltadas (origen no excel Clinni): ${skipped}`);
  if (!EXECUTE) console.log("\nRe-ejecuta con --execute para aplicar.");
  process.exit(0);
}
main();
