/**
 * Lee groupClasses de abril 2026 y los agrupa por (día de semana + hora +
 * nombre/título) para poder mostrar el patrón semanal recurrente.
 *
 * Solo lectura — no modifica nada.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/list_april_classes.js
 */

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "salufitnewapp",
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

const DIAS = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];

async function main() {
  const startApr = new Date(Date.UTC(2026, 3, 1, 0, 0, 0));   // 1 abril 00:00 UTC
  const endApr   = new Date(Date.UTC(2026, 4, 1, 0, 0, 0));   // 1 mayo 00:00 UTC

  // Probamos con el campo más probable. groupClasses suele tener
  // "fechaHoraInicio" como Timestamp.
  const snap = await db
      .collection("groupClasses")
      .where("fechaHoraInicio", ">=", admin.firestore.Timestamp.fromDate(startApr))
      .where("fechaHoraInicio", "<", admin.firestore.Timestamp.fromDate(endApr))
      .get();

  console.log(`\n📊 Total clases groupClasses en abril 2026: ${snap.size}\n`);
  if (snap.empty) {
    // Diagnóstico: vemos los nombres de campo de un doc cualquiera.
    const any = await db.collection("groupClasses").limit(3).get();
    if (any.size > 0) {
      console.log("ℹ️  La colección tiene docs pero ninguno en abril. Muestra de campos:");
      any.docs.forEach((d, i) => {
        const data = d.data();
        const keys = Object.keys(data).sort();
        console.log(`  doc ${i + 1} (${d.id}): ${keys.join(", ")}`);
      });
    } else {
      console.log("⚠️ La colección groupClasses no tiene documentos.");
    }
    process.exit(0);
  }

  // Agrupamos por (DOW, HH:MM, titulo, profesor) ignorando aforo y aforoActual.
  const buckets = new Map();
  let totalSinFecha = 0;
  for (const doc of snap.docs) {
    const d = doc.data();
    const fecha = d.fechaHoraInicio?.toDate?.();
    if (!fecha) { totalSinFecha++; continue; }

    // DOW y HH:MM en zona horaria Madrid (la app es ES).
    const dowStr = fecha.toLocaleString("en-US", {
      timeZone: "Europe/Madrid",
      weekday: "long",
    });
    const dowIdx = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"].indexOf(dowStr);
    const hora = fecha.toLocaleString("es-ES", {
      timeZone: "Europe/Madrid",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });

    const titulo = (d.titulo ?? d.nombre ?? d.tipo ?? "(sin título)").trim();
    const profesor = (d.profesorNombre ?? d.profesor ?? d.instructor ?? "").trim();
    const duracion = d.duracionMinutos ?? d.duracion ?? "";
    const aforo = d.aforoMaximo ?? d.aforo ?? "";

    const key = `${dowIdx}|${hora}|${titulo}|${profesor}`;
    if (!buckets.has(key)) {
      buckets.set(key, {
        dowIdx, hora, titulo, profesor, duracion, aforo, count: 0, fechas: [],
      });
    }
    const b = buckets.get(key);
    b.count++;
    b.fechas.push(fecha.toLocaleDateString("es-ES", {timeZone: "Europe/Madrid"}));
  }

  if (totalSinFecha > 0) {
    console.log(`⚠️ ${totalSinFecha} doc(s) sin fechaHoraInicio (ignorados)\n`);
  }

  // Ordenamos por DOW (lun-dom) luego hora.
  const ordered = Array.from(buckets.values()).sort((a, b) => {
    // Lunes primero (1) ... Domingo último (0 -> 7)
    const da = a.dowIdx === 0 ? 7 : a.dowIdx;
    const db_ = b.dowIdx === 0 ? 7 : b.dowIdx;
    if (da !== db_) return da - db_;
    return a.hora.localeCompare(b.hora);
  });

  let prevDow = -1;
  for (const b of ordered) {
    if (b.dowIdx !== prevDow) {
      console.log(`\n=== ${DIAS[b.dowIdx].toUpperCase()} ===`);
      prevDow = b.dowIdx;
    }
    const profStr = b.profesor ? ` · ${b.profesor}` : "";
    const durStr = b.duracion ? ` · ${b.duracion}min` : "";
    const aforoStr = b.aforo ? ` · aforo ${b.aforo}` : "";
    console.log(`  ${b.hora}  ${b.titulo}${profStr}${durStr}${aforoStr}  (×${b.count} en abril)`);
  }
  console.log(`\n📊 Patrones semanales únicos: ${ordered.length}`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
