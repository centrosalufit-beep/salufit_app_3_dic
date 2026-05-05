/**
 * Auditoría exhaustiva del bot WhatsApp y recordatorios.
 * Solo lectura — no modifica nada.
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
  console.log("\n══════════════ AUDITORÍA BOT WHATSAPP ══════════════\n");

  // ─────────────────────────────────────────────────────────────
  console.log("1️⃣  config/whatsapp_bot");
  // ─────────────────────────────────────────────────────────────
  const cfgDoc = await db.collection("config").doc("whatsapp_bot").get();
  if (!cfgDoc.exists) {
    console.log("   ⚠️ NO existe — usando defaults hardcoded");
  } else {
    const cfg = cfgDoc.data();
    console.log(`   activo: ${cfg.activo}`);
    console.log(`   whatsappPhoneId: ${cfg.whatsappPhoneId}`);
    console.log(`   horasAntelacionRecordatorio: ${cfg.horasAntelacionRecordatorio ?? 24} (default)`);
    console.log(`   grupoRecepcionId: ${cfg.grupoRecepcionId || "❌ EMPTY"}`);
    console.log(`   telefonoRecepcion: ${cfg.telefonoRecepcion || "(default fallback)"}`);
  }

  // ─────────────────────────────────────────────────────────────
  console.log("\n2️⃣  Citas pendientes futuras — distribución por hora ES");
  // ─────────────────────────────────────────────────────────────
  const now = admin.firestore.Timestamp.now();
  const futureSnap = await db.collection("clinni_appointments")
      .where("estado", "==", "pendiente")
      .where("fechaCita", ">=", now)
      .get();
  console.log(`   Total: ${futureSnap.size}`);

  const horaCounts = {};
  let withoutPhone = 0;
  let withoutPhoneAndOriginExcel = 0;
  let recEnviadosCount = 0;
  for (const doc of futureSnap.docs) {
    const d = doc.data();
    const f = d.fechaCita?.toDate?.();
    if (!f) continue;
    const hora = parseInt(f.toLocaleString("es-ES", {
      timeZone: "Europe/Madrid", hour: "2-digit", hour12: false,
    }), 10);
    horaCounts[hora] = (horaCounts[hora] || 0) + 1;
    if (!d.pacienteTelefono) {
      withoutPhone++;
      if (String(d.origenExcel || "").startsWith("informe_citas_")) {
        withoutPhoneAndOriginExcel++;
      }
    }
    if (d.recordatorioEnviado === true) recEnviadosCount++;
  }
  console.log(`   Sin teléfono: ${withoutPhone} (de Excel: ${withoutPhoneAndOriginExcel})`);
  console.log(`   recordatorioEnviado=true: ${recEnviadosCount}`);
  console.log(`   recordatorioEnviado=false: ${futureSnap.size - recEnviadosCount}`);
  console.log(`\n   Distribución horas:`);
  Object.entries(horaCounts).sort(([a], [b]) => parseInt(a) - parseInt(b))
      .forEach(([h, n]) => console.log(`      ${String(h).padStart(2, "0")}h  ${"█".repeat(Math.min(n, 50))} ${n}`));

  // ─────────────────────────────────────────────────────────────
  console.log("\n3️⃣  Citas en ventana actual del cron T-20h a T+48h");
  // ─────────────────────────────────────────────────────────────
  const desde = new Date(Date.now() + 20 * 3600000);
  const hasta = new Date(Date.now() + 48 * 3600000);
  const windowSnap = await db.collection("clinni_appointments")
      .where("recordatorioEnviado", "==", false)
      .where("estado", "==", "pendiente")
      .where("fechaCita", ">=", admin.firestore.Timestamp.fromDate(desde))
      .where("fechaCita", "<=", admin.firestore.Timestamp.fromDate(hasta))
      .get();
  console.log(`   Citas que el próximo cron disparará: ${windowSnap.size}`);
  console.log(`   (ventana: ${desde.toLocaleString("es-ES", {timeZone: "Europe/Madrid"})} → ${hasta.toLocaleString("es-ES", {timeZone: "Europe/Madrid"})} ES)`);
  windowSnap.docs.slice(0, 8).forEach((d) => {
    const dd = d.data();
    const f = dd.fechaCita?.toDate?.();
    console.log(`      • ${f.toLocaleString("es-ES", {timeZone: "Europe/Madrid"})} | ${dd.pacienteNombre.slice(0, 25)} | tel=${dd.pacienteTelefono || "❌ NONE"}`);
  });

  // ─────────────────────────────────────────────────────────────
  console.log("\n4️⃣  whatsapp_conversations recientes (últimas 24h)");
  // ─────────────────────────────────────────────────────────────
  const since = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 24*3600000));
  const convSnap = await db.collection("whatsapp_conversations")
      .where("fechaCreacion", ">=", since)
      .orderBy("fechaCreacion", "desc")
      .limit(15)
      .get();
  console.log(`   Total nuevas conversaciones: ${convSnap.size}`);
  const byTipo = {};
  const byEstado = {};
  for (const doc of convSnap.docs) {
    const d = doc.data();
    byTipo[d.tipo] = (byTipo[d.tipo] || 0) + 1;
    byEstado[d.estado] = (byEstado[d.estado] || 0) + 1;
  }
  console.log(`   Por tipo:    ${JSON.stringify(byTipo)}`);
  console.log(`   Por estado:  ${JSON.stringify(byEstado)}`);

  // ─────────────────────────────────────────────────────────────
  console.log("\n5️⃣  Citas con problema potencial (mañana 5/5 + pasado 6/5)");
  // ─────────────────────────────────────────────────────────────
  const tomMor = new Date(Date.now() + 6 * 3600000); // próx 6h+
  const dayAfter = new Date(Date.now() + 60 * 3600000);
  const todayTomSnap = await db.collection("clinni_appointments")
      .where("estado", "==", "pendiente")
      .where("fechaCita", ">=", admin.firestore.Timestamp.fromDate(tomMor))
      .where("fechaCita", "<=", admin.firestore.Timestamp.fromDate(dayAfter))
      .orderBy("fechaCita")
      .get();
  console.log(`   Citas próximas 6-60h: ${todayTomSnap.size}`);
  // Buscamos las que tienen recordatorioEnviado=true (estas son de la
  // 1ª tanda con bug — el cliente ya recibió hora INCORRECTA)
  let yaEnviadasConBug = 0;
  let pendientesEnviar = 0;
  for (const doc of todayTomSnap.docs) {
    const d = doc.data();
    if (d.recordatorioEnviado === true) yaEnviadasConBug++;
    else pendientesEnviar++;
  }
  console.log(`   Pendientes de enviar (con hora correcta tras fix): ${pendientesEnviar}`);
  console.log(`   Ya enviadas previamente (potencialmente con bug ANTES del fix): ${yaEnviadasConBug}`);

  // ─────────────────────────────────────────────────────────────
  console.log("\n6️⃣  Citas duplicadas (mismo telefono + dia, horas distintas)");
  // ─────────────────────────────────────────────────────────────
  const byKey = new Map();
  for (const doc of futureSnap.docs) {
    const d = doc.data();
    const tel = d.pacienteTelefono;
    const f = d.fechaCita?.toDate?.();
    if (!tel || !f) continue;
    const day = f.toLocaleString("es-ES", {timeZone: "Europe/Madrid",
      day: "2-digit", month: "2-digit", year: "numeric"});
    const key = `${tel}_${day}`;
    if (!byKey.has(key)) byKey.set(key, []);
    byKey.get(key).push({
      hora: f.toLocaleString("es-ES", {timeZone: "Europe/Madrid",
        hour: "2-digit", minute: "2-digit", hour12: false}),
      paciente: d.pacienteNombre, prof: d.profesional,
    });
  }
  let dupCount = 0;
  for (const [k, citas] of byKey) {
    if (citas.length > 1) dupCount++;
  }
  console.log(`   Pacientes con +1 cita el mismo día: ${dupCount}`);
  console.log(`   ⚠️ Recibirán un recordatorio POR CADA cita → posible spam`);

  // ─────────────────────────────────────────────────────────────
  console.log("\n7️⃣  Pacientes sin teléfono (cita registrada pero NO se puede notificar)");
  // ─────────────────────────────────────────────────────────────
  console.log(`   Total: ${withoutPhone}/${futureSnap.size} citas (${(withoutPhone*100/futureSnap.size).toFixed(1)}%)`);
  console.log(`   Causa probable: paciente no en clinni_patients o nombre no matchea`);

  process.exit(0);
}

main().catch((e) => {console.error("Error:", e); process.exit(1);});
