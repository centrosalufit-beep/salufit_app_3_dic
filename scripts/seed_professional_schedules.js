/**
 * Seed de la colección `professional_schedules` en Firestore.
 *
 * Fuente de datos: scripts/professional_schedules_data.json
 *
 * Uso:
 *   1) Asegúrate de tener Application Default Credentials configuradas:
 *        gcloud auth application-default login
 *      o, si tienes un service-account.json:
 *        export GOOGLE_APPLICATION_CREDENTIALS=/ruta/al/service-account.json
 *
 *   2) Ejecuta desde la raíz del repo:
 *        node scripts/seed_professional_schedules.js
 *
 *   3) Idempotente: si los docs ya existen, los sobrescribe (set, no add).
 *      Si quieres preservar campos extra creados por la app, cambia
 *      `.set(data)` por `.set(data, { merge: true })` más abajo.
 */

const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");

const PROJECT_ID = "salufitnewapp";
const DATA_PATH = path.join(__dirname, "professional_schedules_data.json");

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: PROJECT_ID,
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

async function main() {
  const raw = fs.readFileSync(DATA_PATH, "utf8");
  const data = JSON.parse(raw);
  const ids = Object.keys(data);
  console.log(`Sembrando ${ids.length} profesionales en ${PROJECT_ID}/professional_schedules...`);

  let ok = 0;
  let fail = 0;
  for (const id of ids) {
    try {
      await db.collection("professional_schedules").doc(id).set({
        ...data[id],
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        seedSource: "scripts/seed_professional_schedules.js",
      });
      console.log(`  ✓ ${id} (${data[id].nombre})`);
      ok++;
    } catch (e) {
      console.error(`  ✗ ${id}: ${e.message}`);
      fail++;
    }
  }
  console.log(`\nHecho: ${ok} OK, ${fail} fallidos.`);
  process.exit(fail === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error("Error fatal:", e);
  process.exit(1);
});
