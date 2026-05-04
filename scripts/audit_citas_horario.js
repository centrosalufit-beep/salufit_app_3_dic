/**
 * Audita las citas de mayo 2026 mostrando fechaCita en UTC y en
 * Europe/Madrid, junto con su origen, para detectar si hay un offset
 * sistemático provocado por bug en parseDate / setHours.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/audit_citas_horario.js
 */

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "salufitnewapp",
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

async function main() {
  // Cogemos un sample variado: las próximas 30 citas pendientes.
  const now = admin.firestore.Timestamp.now();
  const snap = await db
      .collection("clinni_appointments")
      .where("estado", "==", "pendiente")
      .where("fechaCita", ">=", now)
      .orderBy("fechaCita")
      .limit(30)
      .get();

  console.log(`\n📊 Próximas ${snap.size} citas pendientes:\n`);

  // Agrupamos por origen para detectar patrón.
  const byOrigen = new Map();

  for (const doc of snap.docs) {
    const d = doc.data();
    const fecha = d.fechaCita?.toDate?.();
    if (!fecha) continue;

    const utcStr = fecha.toISOString();
    const madridStr = fecha.toLocaleString("es-ES", {
      timeZone: "Europe/Madrid",
      hour: "2-digit",
      minute: "2-digit",
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour12: false,
    });
    const utcHour = fecha.getUTCHours();
    const utcMin = fecha.getUTCMinutes();
    const utcHourStr = `${String(utcHour).padStart(2, "0")}:${String(utcMin).padStart(2, "0")}`;
    const origen = (d.origenExcel || d.creadoPor || "(sin origen)").slice(0, 50);

    if (!byOrigen.has(origen)) byOrigen.set(origen, []);
    byOrigen.get(origen).push({
      id: doc.id,
      paciente: d.pacienteNombre,
      profesional: d.profesional,
      utc: utcHourStr,
      madrid: madridStr,
      utcFull: utcStr,
    });
  }

  for (const [origen, citas] of byOrigen) {
    console.log(`\n=== ORIGEN: ${origen} (${citas.length}) ===`);
    citas.slice(0, 6).forEach((c) => {
      console.log(`  ${c.madrid} ES   | UTC ${c.utc}   | ${c.paciente.slice(0, 25).padEnd(25)} | ${c.profesional.slice(0, 20)}`);
    });
  }

  // Comparativa explícita: si la cita está bien guardada, UTC debería
  // ser hora_madrid - 2 (CEST mayo). Verificamos si hay desfase.
  console.log("\n\n🔍 ANÁLISIS DE DESFASE:");
  console.log("Esperado en mayo 2026 (CEST): UTC = hora_madrid - 2");
  console.log("Si vemos UTC = hora_madrid → cita guardada con +2h offset");
  console.log("Si vemos UTC = hora_madrid + 10 → cita guardada con +12h offset (síntoma reportado)\n");

  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
