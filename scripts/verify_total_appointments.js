/**
 * Diagnóstico extendido: cuántas citas hay con cada origenExcel,
 * cuántas en distintos rangos, y muestra de las que NO caen en mayo.
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
  const all = await db.collection("clinni_appointments").get();
  console.log(`\n📊 Total clinni_appointments: ${all.size}`);

  const byOrigen = {};
  const byMonth = {};
  let withoutDate = 0;
  let pendientes = 0;
  const samples = [];

  for (const doc of all.docs) {
    const d = doc.data();
    const origen = d.origenExcel || "(sin)";
    byOrigen[origen] = (byOrigen[origen] || 0) + 1;
    const fechaJs = d.fechaCita?.toDate?.();
    if (!fechaJs) {
      withoutDate++;
      continue;
    }
    const ymKey = `${fechaJs.getUTCFullYear()}-${String(fechaJs.getUTCMonth() + 1).padStart(2, "0")}`;
    byMonth[ymKey] = (byMonth[ymKey] || 0) + 1;
    if (d.estado === "pendiente") pendientes++;
    if (samples.length < 3) {
      samples.push({
        id: doc.id,
        fechaCita: fechaJs.toISOString(),
        local: fechaJs.toLocaleString("es-ES", {timeZone: "Europe/Madrid"}),
        paciente: d.pacienteNombre,
        prof: d.profesional,
        origen,
      });
    }
  }

  console.log(`\nPor origenExcel:`);
  Object.entries(byOrigen).sort(([, a], [, b]) => b - a)
      .forEach(([k, v]) => console.log(`   ${k}: ${v}`));

  console.log(`\nPor mes (UTC):`);
  Object.entries(byMonth).sort()
      .forEach(([k, v]) => console.log(`   ${k}: ${v}`));

  console.log(`\nPendientes total: ${pendientes}`);
  console.log(`Sin fecha: ${withoutDate}`);

  console.log(`\n3 muestras (ojo: si UTC pone abril pero local mayo, hay desfase TZ):`);
  samples.forEach((s) => console.log(JSON.stringify(s, null, 2)));

  // Buscar específicamente las que están "casi en mayo" (último día abril noche, primer día mayo madrugada)
  const apr30Late = await db.collection("clinni_appointments")
      .where("fechaCita", ">=", admin.firestore.Timestamp.fromDate(new Date(Date.UTC(2026, 3, 30, 22, 0))))
      .where("fechaCita", "<", admin.firestore.Timestamp.fromDate(new Date(Date.UTC(2026, 4, 1, 0, 0))))
      .get();
  console.log(`\nCitas con fechaCita entre 30/4 22:00 UTC y 1/5 00:00 UTC: ${apr30Late.size}`);

  // Y todas las pendientes (sin filtro fecha)
  const allPend = await db.collection("clinni_appointments")
      .where("estado", "==", "pendiente").get();
  console.log(`\nTotal en estado pendiente (cualquier fecha): ${allPend.size}`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
