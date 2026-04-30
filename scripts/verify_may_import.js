/**
 * Verifica las citas importadas para mayo 2026:
 *  - Cuenta total en clinni_appointments con fechaCita en [1/5, 1/6).
 *  - Distribución por profesional.
 *  - Citas sin teléfono válido (debería ser 0).
 *  - Top 5 más cercanas (próximas a enviar recordatorio).
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
  const startMay = new Date(Date.UTC(2026, 4, 1, 0, 0, 0));
  const startJun = new Date(Date.UTC(2026, 5, 1, 0, 0, 0));

  const snap = await db.collection("clinni_appointments")
      .where("fechaCita", ">=", admin.firestore.Timestamp.fromDate(startMay))
      .where("fechaCita", "<", admin.firestore.Timestamp.fromDate(startJun))
      .get();

  console.log(`\n📊 Total citas mayo 2026: ${snap.size}`);

  const porProfesional = {};
  const porDia = {};
  let sinTel = 0;
  let pendientes = 0;
  const proximas = [];

  for (const doc of snap.docs) {
    const d = doc.data();
    const prof = d.profesional || "(sin)";
    porProfesional[prof] = (porProfesional[prof] || 0) + 1;
    const fechaJs = d.fechaCita?.toDate?.();
    if (fechaJs) {
      const dia = fechaJs.toLocaleDateString("es-ES", {timeZone: "Europe/Madrid"});
      porDia[dia] = (porDia[dia] || 0) + 1;
      proximas.push({fecha: fechaJs, prof, paciente: d.pacienteNombre,
        servicio: d.servicio, tel: d.pacienteTelefono});
    }
    if (!d.pacienteTelefono || !/^\d{9,15}$/.test(d.pacienteTelefono)) sinTel++;
    if (d.estado === "pendiente") pendientes++;
  }

  console.log(`📞 Citas sin teléfono válido: ${sinTel}`);
  console.log(`⏳ Citas en estado pendiente: ${pendientes}`);

  console.log(`\n👨‍⚕️ Por profesional:`);
  Object.entries(porProfesional)
      .sort(([, a], [, b]) => b - a)
      .forEach(([k, v]) => console.log(`   ${k}: ${v}`));

  console.log(`\n📅 Por día (top 10):`);
  Object.entries(porDia)
      .sort(([a], [b]) => {
        const [da, ma] = a.split("/").map(Number);
        const [db_, mb] = b.split("/").map(Number);
        return ma === mb ? da - db_ : ma - mb;
      })
      .slice(0, 10)
      .forEach(([k, v]) => console.log(`   ${k}: ${v}`));

  console.log(`\n🔔 5 citas más próximas (las que disparará el cron T-24h):`);
  proximas
      .sort((a, b) => a.fecha - b.fecha)
      .slice(0, 5)
      .forEach((c) => console.log(
          `   ${c.fecha.toLocaleString("es-ES", {timeZone: "Europe/Madrid"})}` +
          ` — ${c.paciente} con ${c.prof} (${c.servicio}) — ${c.tel}`,
      ));

  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
