/**
 * MIGRACIÓN: corrige el offset +2h de las citas importadas con el bug
 * de timezone (setHours en UTC en lugar de Madrid). Aplica SOLO a citas
 * cuyo `origenExcel` empieza por "informe_citas_" (las del importador
 * Clinni con bug). Resta 2h al fechaCita Y al deduplicationKey
 * regenerado.
 *
 * NO toca:
 *  - Citas creadas por scripts manualmente (origenExcel con prefix "scripts/").
 *  - Citas creadas por panel admin (origen="replicate_classes_month").
 *  - Citas con estado != pendiente (cambiar atendidas/canceladas no
 *    tiene sentido — ya se cobraron/cerraron a su hora real).
 *
 * Sólo aplicamos a citas FUTURAS o de hoy/ayer (los recordatorios
 * pendientes son los que importan).
 *
 * IMPORTANTE — verano CEST: el offset es UTC+2. En invierno (CET) sería
 * UTC+1. La gran mayoría de las citas reportadas están en mayo (verano)
 * así que -2h es correcto. Si alguna cita cae en una franja DST mezcla,
 * usamos buildMadridDate con la fecha CORRECTA (recalculada como ES).
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/fix_citas_offset_2h.js
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/fix_citas_offset_2h.js --execute
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
console.log(`Modo: ${EXECUTE ? "🔴 EXECUTE — escribe en Firestore" : "🟡 DRY-RUN — solo simula"}\n`);

/**
 * Reinterpreta un Date "naive" (creado en UTC con horas ES) al instante
 * UTC correcto. Maneja DST:
 *   - mayo→octubre: CEST UTC+2 → resta 2h
 *   - noviembre→marzo: CET UTC+1 → resta 1h
 *   - cambio de hora último domingo marzo/octubre: usamos el offset que
 *     tendría Madrid en ese momento
 */
function reinterpretAsMadrid(naive) {
  const sample = new Date(Date.UTC(
      naive.getUTCFullYear(),
      naive.getUTCMonth(),
      naive.getUTCDate(),
      naive.getUTCHours(),
      naive.getUTCMinutes(),
  ));
  const localMadrid = new Date(
      sample.toLocaleString("en-US", {timeZone: "Europe/Madrid"}),
  );
  const utcEquiv = new Date(
      sample.toLocaleString("en-US", {timeZone: "UTC"}),
  );
  const offsetMs = localMadrid.getTime() - utcEquiv.getTime();
  return new Date(sample.getTime() - offsetMs);
}

function buildDeduplicationKey(tel, fecha, prof) {
  return `${tel}_${fecha.toISOString()}_${(prof || "").trim().toLowerCase()}`;
}

async function main() {
  const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000); // hoy-1 día

  const snap = await db.collection("clinni_appointments")
      .where("estado", "==", "pendiente")
      .where("fechaCita", ">=", admin.firestore.Timestamp.fromDate(cutoff))
      .get();

  console.log(`📊 Total citas pendientes >= ayer: ${snap.size}\n`);

  let processed = 0;
  let skippedNotImport = 0;
  let skippedAlreadyOk = 0;
  const samples = [];

  // Procesar en chunks de 400 para no saturar batch.
  const docs = snap.docs;
  for (let i = 0; i < docs.length; i += 400) {
    const slice = docs.slice(i, i + 400);
    const batch = db.batch();
    let inThisBatch = 0;

    for (const doc of slice) {
      const d = doc.data();
      const origen = d.origenExcel || d.creadoPor || "";

      // Solo importadas del Excel de Clinni con bug.
      if (!String(origen).startsWith("informe_citas_")) {
        skippedNotImport++;
        continue;
      }

      const fechaActual = d.fechaCita?.toDate?.();
      if (!fechaActual) continue;

      // Reinterpretar: el "naive" UTC actual son los horarios ES.
      const fechaCorrecta = reinterpretAsMadrid(fechaActual);

      // Si ya está bien (diff = 0), saltamos.
      const diffH = (fechaActual.getTime() - fechaCorrecta.getTime()) / 3600000;
      if (Math.abs(diffH) < 0.1) {
        skippedAlreadyOk++;
        continue;
      }

      const newDedupKey = buildDeduplicationKey(
          d.pacienteTelefono,
          fechaCorrecta,
          d.profesional,
      );

      if (samples.length < 6) {
        samples.push({
          paciente: d.pacienteNombre,
          antes: fechaActual.toLocaleString("es-ES", {timeZone: "Europe/Madrid"}),
          despues: fechaCorrecta.toLocaleString("es-ES", {timeZone: "Europe/Madrid"}),
          diffH: diffH.toFixed(1),
        });
      }

      if (EXECUTE) {
        batch.update(doc.ref, {
          fechaCita: admin.firestore.Timestamp.fromDate(fechaCorrecta),
          deduplicationKey: newDedupKey,
          fechaCitaCorregidaEn: admin.firestore.FieldValue.serverTimestamp(),
          fechaCitaAntes: admin.firestore.Timestamp.fromDate(fechaActual),
          // Reset recordatorio para que el cron lo reconsidere con la
          // fecha correcta (puede que ya no esté en la ventana T-24h).
          recordatorioEnviado: false,
          fechaRecordatorio: null,
        });
        inThisBatch++;
      }
      processed++;
    }

    if (EXECUTE && inThisBatch > 0) {
      await batch.commit();
      console.log(`  ✅ Batch ${Math.floor(i/400)+1}: ${inThisBatch} citas actualizadas`);
    }
  }

  console.log(`\n📊 Resumen:`);
  console.log(`   Procesadas (offset corregido): ${processed}`);
  console.log(`   Saltadas (no importadas Clinni): ${skippedNotImport}`);
  console.log(`   Saltadas (ya correctas): ${skippedAlreadyOk}`);

  if (samples.length > 0) {
    console.log(`\n🔍 Muestra de cambios:`);
    samples.forEach((s) => {
      console.log(`   ${s.paciente.slice(0,28).padEnd(28)} | ${s.antes} → ${s.despues}  (Δ ${s.diffH}h)`);
    });
  }

  if (!EXECUTE) {
    console.log(`\n🟡 Dry-run terminado. Re-ejecuta con --execute para aplicar.`);
  } else {
    console.log(`\n✅ Migración completada. ${processed} citas movidas a su hora correcta.`);
    console.log(`   recordatorioEnviado=false → el cron T-24h volverá a evaluar cada cita.`);
  }
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
