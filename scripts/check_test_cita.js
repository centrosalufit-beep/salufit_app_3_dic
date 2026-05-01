const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({projectId: "salufitnewapp",
    credential: admin.credential.applicationDefault()});
}
const db = admin.firestore();
async function main() {
  const snap = await db.collection("clinni_appointments")
      .doc("test_david_tomorrow_18h").get();
  if (!snap.exists) { console.log("NO EXISTE"); process.exit(0); }
  const d = snap.data();
  const fc = d.fechaCita.toDate();
  const now = new Date();
  const horasFaltan = (fc.getTime() - now.getTime()) / 3600000;
  console.log(JSON.stringify({
    estado: d.estado,
    recordatorioEnviado: d.recordatorioEnviado,
    fechaCita_iso: fc.toISOString(),
    fechaCita_local: fc.toLocaleString("es-ES", {timeZone: "Europe/Madrid"}),
    horasFaltan: horasFaltan.toFixed(2),
    pacienteTelefono: d.pacienteTelefono,
    profesional: d.profesional,
    now_local: now.toLocaleString("es-ES", {timeZone: "Europe/Madrid"}),
  }, null, 2));
  process.exit(0);
}
main();
