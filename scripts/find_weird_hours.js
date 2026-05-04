/**
 * Busca citas con horas anómalas (21:00+, antes de 7:00) que podrían
 * ser síntoma del bug reportado por clientes.
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
  const endJun = new Date(Date.UTC(2026, 5, 30, 0, 0, 0));

  const snap = await db.collection("clinni_appointments")
      .where("fechaCita", ">=", admin.firestore.Timestamp.fromDate(startMay))
      .where("fechaCita", "<", admin.firestore.Timestamp.fromDate(endJun))
      .get();

  console.log(`Total citas mayo+junio: ${snap.size}\n`);

  const weird = [];
  const horaCounts = {};

  for (const doc of snap.docs) {
    const d = doc.data();
    const fecha = d.fechaCita?.toDate?.();
    if (!fecha) continue;

    const madridFmt = fecha.toLocaleString("es-ES", {
      timeZone: "Europe/Madrid",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
    const horaES = parseInt(madridFmt.split(":")[0], 10);
    horaCounts[horaES] = (horaCounts[horaES] || 0) + 1;

    if (horaES < 7 || horaES >= 21) {
      weird.push({
        id: doc.id,
        paciente: d.pacienteNombre,
        prof: d.profesional,
        hora_madrid: madridFmt,
        utc: fecha.toISOString(),
        recordatorioEnviado: d.recordatorioEnviado,
        origen: (d.origenExcel || d.creadoPor || "(?)").slice(0, 60),
      });
    }
  }

  console.log("📊 Distribución por hora ES (mayo+junio):");
  Object.entries(horaCounts)
      .sort(([a], [b]) => parseInt(a) - parseInt(b))
      .forEach(([h, n]) => {
        console.log(`   ${String(h).padStart(2, "0")}:00-${String(parseInt(h)+1).padStart(2, "0")}:00  ${n}`);
      });

  if (weird.length > 0) {
    console.log(`\n⚠️ ${weird.length} citas con hora anómala (<7 o ≥21):`);
    weird.slice(0, 20).forEach((c) => {
      console.log(`   ${c.hora_madrid} ES | ${c.paciente.slice(0, 25).padEnd(25)} | ${c.prof.slice(0, 20)} | ${c.origen}`);
    });
  } else {
    console.log("\n✅ Sin citas con hora anómala. Todas en horario laboral 7-21.");
  }

  // Buscar duplicadas (mismo telefono+día con horas distintas):
  console.log("\n\n🔍 Buscando duplicadas (mismo paciente, mismo día, horas distintas):");
  const byPatientDay = new Map();
  for (const doc of snap.docs) {
    const d = doc.data();
    const tel = d.pacienteTelefono;
    const fecha = d.fechaCita?.toDate?.();
    if (!tel || !fecha) continue;
    const dayKey = fecha.toLocaleString("es-ES", {
      timeZone: "Europe/Madrid",
      day: "2-digit", month: "2-digit", year: "numeric",
    });
    const key = `${tel}_${dayKey}`;
    if (!byPatientDay.has(key)) byPatientDay.set(key, []);
    byPatientDay.get(key).push({
      id: doc.id,
      paciente: d.pacienteNombre,
      hora: fecha.toLocaleString("es-ES", {
        timeZone: "Europe/Madrid",
        hour: "2-digit", minute: "2-digit", hour12: false,
      }),
      utc: fecha.toISOString(),
    });
  }
  let dupCount = 0;
  for (const [k, citas] of byPatientDay) {
    if (citas.length > 1) {
      const horas = citas.map((c) => c.hora);
      const horasUnicas = [...new Set(horas)];
      if (horasUnicas.length > 1) {
        dupCount++;
        if (dupCount <= 10) {
          console.log(`   ${k}: ${citas[0].paciente} → horas: ${horas.join(", ")}`);
        }
      }
    }
  }
  console.log(`\nTotal pacientes con citas duplicadas mismo día (horas distintas): ${dupCount}`);

  process.exit(0);
}
main();
