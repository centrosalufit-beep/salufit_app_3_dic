/**
 * Seed inicial de `config/clinic_info` y festivos 2026-2027 en
 * `clinic_holidays`. Idempotente: si ya existen, los actualiza con merge.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/seed_clinic_info.js
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

const CLINIC_INFO = {
  horarios: {
    lunes: {abre: "09:00", cierra: "20:00"},
    martes: {abre: "09:00", cierra: "20:00"},
    miercoles: {abre: "09:00", cierra: "20:00"},
    jueves: {abre: "09:00", cierra: "20:00"},
    viernes: {abre: "09:00", cierra: "20:00"},
    sabado: {abre: "09:00", cierra: "13:00"},
    domingo: null,
  },
  direccion: "Av. Diputación 19, 03710 Calpe (Alicante)",
  googleMapsUrl: "https://maps.app.goo.gl/zuyBpJqbsQ4YdLN26",
  telefonoRecepcion: "+34 629 01 10 55",
  parking:
    "Aparcamiento gratuito en zona azul de la avenida y calles adyacentes. " +
    "Hay parking público a 200 m (Plaza Mayor).",
  comoLlegar:
    "En coche desde la AP-7, salida 63 dirección Calpe centro. " +
    "En autobús: parada Centro Salufit (líneas 1 y 3 del urbano).",
  primeraVisita:
    "En tu primera visita trae documentación previa relevante (informes, " +
    "pruebas, recetas). Te pediremos firmar el consentimiento de protección " +
    "de datos. Llega 5 min antes.",
  servicios: [
    {nombre: "Fisioterapia",
      precio: 45,
      descripcion: "Sesión 30 min con tratamiento manual y ejercicio terapéutico"},
    {nombre: "Primera visita fisioterapia",
      precio: 60,
      descripcion: "Valoración inicial completa, 45 min"},
    {nombre: "Psicología",
      precio: 60,
      descripcion: "Sesión 60 min"},
    {nombre: "Odontología",
      descripcion: "Precio variable según tratamiento. Consulta valoración gratuita."},
    {nombre: "Podología",
      precio: 35,
      descripcion: "Quiropodia básica 30 min"},
  ],
  bienvenidaNuevoPaciente:
    "¡Hola! 👋 Te escribe el bot del Centro Salufit. Si quieres pedir cita o " +
    "información, te ayudo en un momento. ¿En qué puedo ayudarte?",
};

// Festivos hardcoded 2026 (los que ya conocemos). El panel admin podrá
// añadir más cuando el usuario los meta. NO sobrescribimos los que ya
// existan (idempotente).
const HOLIDAYS_2026 = [
  {fecha: "2026-01-01", motivo: "Año Nuevo", tipo: "festivo"},
  {fecha: "2026-01-06", motivo: "Reyes", tipo: "festivo"},
  {fecha: "2026-03-19", motivo: "San José (CV)", tipo: "festivo"},
  {fecha: "2026-04-03", motivo: "Viernes Santo", tipo: "festivo"},
  {fecha: "2026-04-06", motivo: "Lunes de Pascua (CV)", tipo: "festivo"},
  {fecha: "2026-05-01", motivo: "Día del Trabajo", tipo: "festivo"},
  {fecha: "2026-06-24", motivo: "Sant Joan (CV)", tipo: "festivo"},
  {fecha: "2026-08-05", motivo: "Madre de Dios de las Nieves (Calpe)",
    tipo: "festivo"},
  {fecha: "2026-08-15", motivo: "Asunción", tipo: "festivo"},
  {fecha: "2026-10-09", motivo: "Día Comunidad Valenciana", tipo: "festivo"},
  {fecha: "2026-10-12", motivo: "Fiesta Nacional España", tipo: "festivo"},
  {fecha: "2026-10-22", motivo: "Stmo Cristo del Sudor (Calpe)", tipo: "festivo"},
  {fecha: "2026-12-08", motivo: "Inmaculada", tipo: "festivo"},
  {fecha: "2026-12-25", motivo: "Navidad", tipo: "festivo"},
];

async function main() {
  // 1) clinic_info — set con merge para no perder lo que recepción haya
  //    editado manualmente.
  const infoRef = db.collection("config").doc("clinic_info");
  const before = await infoRef.get();
  if (before.exists) {
    console.log("ℹ️  config/clinic_info ya existe — haciendo merge sin sobrescribir campos del usuario");
    await infoRef.set(CLINIC_INFO, {merge: true});
  } else {
    await infoRef.set(CLINIC_INFO);
    console.log("✅ config/clinic_info creado por primera vez");
  }

  // 2) clinic_holidays — un doc por fecha, ID = fecha. set sin merge para
  //    homogeneizar tipo/motivo, pero solo si NO existe (no pisamos lo
  //    que recepción haya editado).
  let creados = 0;
  let yaExistian = 0;
  for (const h of HOLIDAYS_2026) {
    const ref = db.collection("clinic_holidays").doc(h.fecha);
    const snap = await ref.get();
    if (snap.exists) {
      yaExistian++;
    } else {
      await ref.set({
        ...h,
        creadoEn: admin.firestore.FieldValue.serverTimestamp(),
        origen: "seed",
      });
      creados++;
    }
  }
  console.log(`✅ clinic_holidays: ${creados} creados, ${yaExistian} ya existían`);

  console.log("\n🎉 Seed completado.");
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
