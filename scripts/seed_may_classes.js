/**
 * Crea las clases grupales de mayo 2026 según el patrón semanal
 * confirmado por el usuario el 1/5/2026.
 *
 * Idempotente: cada clase se identifica por un docId determinístico
 * `mayo2026_<diaIso>_<HHMM>_<slug-titulo>` para que la re-ejecución no
 * genere duplicados.
 *
 * Respeta `clinic_holidays` — si una fecha cae en festivo o cierre
 * excepcional, salta esa clase.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/seed_may_classes.js
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/seed_may_classes.js --dry-run
 */

const admin = require("firebase-admin");

const PROJECT_ID = "salufitnewapp";
const DRY_RUN = process.argv.includes("--dry-run");
const AFORO = 12;
const DURACION_MIN = 60;

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: PROJECT_ID,
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

// Patrón semanal — clave = día de la semana ISO (1=lunes, 7=domingo).
// Cada entrada es un array de {hora:"HH:MM", titulo, monitor}.
const PATTERN = {
  1: [ // Lunes
    {hora: "07:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "08:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "09:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "11:00", titulo: "Tribu Activa", monitor: "Silvio"},
    {hora: "16:00", titulo: "Explora Kids", monitor: "David, Sara"},
    {hora: "17:00", titulo: "Ejercicio Terapéutico", monitor: "Álvaro, Ibtissam, David"},
    {hora: "18:00", titulo: "Ejercicio Terapéutico", monitor: "Álvaro, Ibtissam, David"},
    {hora: "19:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "20:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
  ],
  2: [ // Martes
    {hora: "07:00", titulo: "Ejercicio Terapéutico", monitor: "Álvaro, Ibtissam, David"},
    {hora: "08:00", titulo: "Ejercicio Terapéutico", monitor: "Álvaro, Ibtissam, David"},
    {hora: "09:00", titulo: "Ejercicio Terapéutico", monitor: "Álvaro, Ibtissam, David"},
    {hora: "10:00", titulo: "Meditación Grupal", monitor: "Ignacio, Noelia"},
    {hora: "16:30", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "17:30", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "18:30", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "19:30", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "20:30", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
  ],
  3: [ // Miércoles
    {hora: "07:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "08:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "09:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "11:00", titulo: "Tribu Activa", monitor: "Silvio"},
    {hora: "16:00", titulo: "Explora Kids", monitor: "David, Sara"},
    {hora: "17:00", titulo: "Ejercicio Terapéutico", monitor: "Álvaro, Ibtissam, David"},
    {hora: "18:00", titulo: "Ejercicio Terapéutico", monitor: "Álvaro, Ibtissam, David"},
    {hora: "19:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "20:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
  ],
  4: [ // Jueves
    {hora: "07:00", titulo: "Ejercicio Terapéutico", monitor: "Álvaro, Ibtissam, David"},
    {hora: "08:00", titulo: "Ejercicio Terapéutico", monitor: "Álvaro, Ibtissam, David"},
    {hora: "09:00", titulo: "Ejercicio Terapéutico", monitor: "Álvaro, Ibtissam, David"},
    {hora: "10:00", titulo: "Meditación Grupal", monitor: "Ignacio, Noelia"},
    {hora: "16:30", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "17:30", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "18:30", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "19:30", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
    {hora: "20:30", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
  ],
  5: [ // Viernes
    {hora: "19:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
  ],
  6: [ // Sábado
    {hora: "09:00", titulo: "Entrenamiento Grupal", monitor: "Silvio"},
  ],
};

function slug(s) {
  return s.toLowerCase()
      .normalize("NFD").replace(/[̀-ͯ]/g, "")
      .replace(/[^a-z0-9]+/g, "_")
      .replace(/^_+|_+$/g, "");
}

function buildLocalMadridDate(year, month, day, hh, mm) {
  // Mayo 2026 está en CEST (UTC+2). Para evitar líos con DST en otros
  // meses, calculamos el offset usando Intl.
  const sample = new Date(Date.UTC(year, month - 1, day, hh, mm));
  // Offset de la zona en ese momento.
  const local = new Date(sample.toLocaleString("en-US", {timeZone: "Europe/Madrid"}));
  const utc = new Date(sample.toLocaleString("en-US", {timeZone: "UTC"}));
  const offsetMs = local.getTime() - utc.getTime();
  return new Date(sample.getTime() - offsetMs);
}

async function loadHolidaySet() {
  const snap = await db.collection("clinic_holidays")
      .where("fecha", ">=", "2026-05-01")
      .where("fecha", "<=", "2026-05-31")
      .get();
  const closed = new Set();
  for (const d of snap.docs) {
    const data = d.data();
    if (data.tipo === "festivo" || data.tipo === "cerrado_excepcional") {
      closed.add(String(data.fecha ?? d.id));
    }
  }
  return closed;
}

async function main() {
  console.log(`Modo: ${DRY_RUN ? "🟡 DRY-RUN" : "🔴 EXECUTE"}\n`);
  const closed = await loadHolidaySet();
  if (closed.size > 0) {
    console.log(`Festivos detectados en mayo: ${[...closed].join(", ")}\n`);
  }

  const created = [];
  const skipped = [];
  const alreadyExisted = [];

  for (let day = 1; day <= 31; day++) {
    const date = new Date(Date.UTC(2026, 4, day));
    // Día ISO 1=lunes ... 7=domingo, en TZ Madrid.
    const dowName = date.toLocaleString("en-US", {timeZone: "Europe/Madrid", weekday: "long"});
    const isoMap = {Monday: 1, Tuesday: 2, Wednesday: 3, Thursday: 4, Friday: 5, Saturday: 6, Sunday: 7};
    const dowIso = isoMap[dowName];
    const slots = PATTERN[dowIso];
    if (!slots) continue;

    const isoDate = `2026-05-${String(day).padStart(2, "0")}`;
    if (closed.has(isoDate)) {
      console.log(`⏭️  ${isoDate} — festivo/cerrado, ${slots.length} clase(s) saltadas`);
      slots.forEach(() => skipped.push(isoDate));
      continue;
    }

    for (const s of slots) {
      const [hh, mm] = s.hora.split(":").map(Number);
      const fechaHoraInicio = buildLocalMadridDate(2026, 5, day, hh, mm);
      const fechaHoraFin = new Date(fechaHoraInicio.getTime() + DURACION_MIN * 60 * 1000);
      const docId = `mayo2026_${isoDate}_${String(hh).padStart(2, "0")}${String(mm).padStart(2, "0")}_${slug(s.titulo)}`;

      const ref = db.collection("groupClasses").doc(docId);
      const snap = await ref.get();
      if (snap.exists) {
        alreadyExisted.push(docId);
        continue;
      }
      if (!DRY_RUN) {
        await ref.set({
          nombre: s.titulo,
          titulo: s.titulo,
          monitor: s.monitor,
          monitorNombre: s.monitor,
          fechaHoraInicio: admin.firestore.Timestamp.fromDate(fechaHoraInicio),
          fechaHoraFin: admin.firestore.Timestamp.fromDate(fechaHoraFin),
          duracionMinutos: DURACION_MIN,
          aforoMaximo: AFORO,
          aforoActual: 0,
          mes: 5,
          anio: 2026,
          dia: day,
          diaSemana: dowIso,
          horaInicio: s.hora,
          activa: true,
          origen: "seed_may_classes_2026",
          creadoEn: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      created.push(docId);
    }
  }

  console.log(`\n✅ ${DRY_RUN ? "Hubieran sido creadas" : "Creadas"}: ${created.length}`);
  console.log(`ℹ️  Ya existían: ${alreadyExisted.length}`);
  console.log(`⏭️  Saltadas por festivo: ${skipped.length}`);
  console.log(`📊 Total esperado: ${created.length + alreadyExisted.length + skipped.length}`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
