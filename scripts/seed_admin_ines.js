/**
 * Seed para Inés María Orihuela en `bbdd` para que pueda activarse
 * vía la pantalla "Primera vez". Al activarse, la Cloud Function
 * `checkAccountStatus` la detectará y le asignará rol admin
 * (porque su email está en ADMIN_EMAILS y/o porque el doc bbdd
 * incluye `rolDefault: "admin"`).
 *
 * Idempotente: si el doc ya existe, lo actualiza con merge.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/seed_admin_ines.js
 *
 * Requiere credenciales de admin SDK (gcloud auth application-default login
 * o GOOGLE_APPLICATION_CREDENTIALS).
 */

const admin = require("firebase-admin");

const PROJECT_ID = "salufitnewapp";

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: PROJECT_ID,
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

const INES = {
  numHistoria: "005711",
  historyId: "005711",
  nombre: "Inés María",
  apellidos: "Orihuela",
  nombreCompleto: "Inés María Orihuela",
  email: "inesmariaoc07@gmail.com",
  telefono: "34633662626",
  // Marcador para que checkAccountStatus le asigne rol admin sin
  // depender de la lista hardcodeada (doble seguro).
  rolDefault: "admin",
  fechaCreacion: admin.firestore.FieldValue.serverTimestamp(),
};

async function main() {
  // Documento ID = numHistoria (005711). Idempotente.
  const ref = db.collection("bbdd").doc(INES.numHistoria);
  await ref.set(INES, { merge: true });

  console.log(`✓ bbdd/${INES.numHistoria} sembrado para ${INES.nombreCompleto}`);
  console.log(`  email:        ${INES.email}`);
  console.log(`  numHistoria:  ${INES.numHistoria}`);
  console.log(`  rolDefault:   ${INES.rolDefault}`);
  console.log("");
  console.log("Próximos pasos para que Inés se registre como admin:");
  console.log("  1. Abrir la app → 'Primera vez' / 'Activar cuenta'");
  console.log("  2. Introducir email: inesmariaoc07@gmail.com");
  console.log("     y número de historia: 005711");
  console.log("  3. Recibirá email para fijar contraseña");
  console.log("  4. Al iniciar sesión por 1ª vez, RoleGate la enviará al panel admin");
}

main().then(() => process.exit(0)).catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
