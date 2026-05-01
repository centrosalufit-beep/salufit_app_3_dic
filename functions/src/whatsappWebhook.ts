/**
 * Cloud Function `whatsappWebhook` (HTTP).
 *
 * Maneja:
 *  - GET: verificación de webhook por Meta (subscribe + verify_token).
 *  - POST: recepción de mensajes de pacientes y eventos de WhatsApp.
 *
 * Pipeline POST:
 *  1. Validar firma X-Hub-Signature-256 (HMAC SHA-256 con APP_SECRET).
 *  2. Responder 200 a Meta INMEDIATAMENTE (Meta reintenta si tarda).
 *  3. Procesar el mensaje en background:
 *     a. Si es interactive (button_reply), gestionar selección de slot
 *        (Fase 2 — reagendación). Por ahora dejamos placeholder.
 *     b. Si es text, clasificar con Claude Haiku, ejecutar acción.
 *  4. Persistir conversación en `whatsapp_conversations`.
 */

import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {sendTextMessage, sendButtonMessage, validateMetaSignature} from "./whatsapp";
import {classifyIntent, BotIntent} from "./claude";
import {fetchMediaAndStore} from "./whatsappMedia";
import {findNextAvailableSlots, shortLabelForSlot, longLabelForSlot, Slot} from "./slots";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

const WHATSAPP_TOKEN = defineSecret("WHATSAPP_TOKEN");
const WHATSAPP_APP_SECRET = defineSecret("WHATSAPP_APP_SECRET");
const WHATSAPP_VERIFY_TOKEN = defineSecret("WHATSAPP_VERIFY_TOKEN");
const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");

interface BotConfig {
  whatsappPhoneId: string;
  grupoRecepcionId: string;
  nombreRecepcion: string;
  horarioAtencionInicio: string; // "HH:mm"
  horarioAtencionFin: string;
  diasLaborables: number[]; // 0=domingo .. 6=sábado
  activo: boolean;
}

const DEFAULT_CONFIG: BotConfig = {
  whatsappPhoneId: "723362620868862",
  grupoRecepcionId: "",
  nombreRecepcion: "Recepción Salufit",
  horarioAtencionInicio: "09:00",
  horarioAtencionFin: "20:00",
  diasLaborables: [1, 2, 3, 4, 5],
  activo: true,
};

async function loadConfig(): Promise<BotConfig> {
  try {
    const doc = await db.collection("config").doc("whatsapp_bot").get();
    if (!doc.exists) return DEFAULT_CONFIG;
    const data = doc.data() ?? {};
    return {
      whatsappPhoneId: (data.whatsappPhoneId as string) || DEFAULT_CONFIG.whatsappPhoneId,
      grupoRecepcionId: (data.grupoRecepcionId as string) || DEFAULT_CONFIG.grupoRecepcionId,
      nombreRecepcion: (data.nombreRecepcion as string) || DEFAULT_CONFIG.nombreRecepcion,
      horarioAtencionInicio:
        (data.horarioAtencionInicio as string) || DEFAULT_CONFIG.horarioAtencionInicio,
      horarioAtencionFin:
        (data.horarioAtencionFin as string) || DEFAULT_CONFIG.horarioAtencionFin,
      diasLaborables:
        (data.diasLaborables as number[]) || DEFAULT_CONFIG.diasLaborables,
      activo: data.activo !== false,
    };
  } catch (e) {
    functions.logger.warn("loadConfig failed, using defaults", e);
    return DEFAULT_CONFIG;
  }
}

function isWithinBusinessHours(now: Date, config: BotConfig): boolean {
  // En España; el container Cloud Function está en UTC, pero Date.toLocaleString
  // con la TZ de España nos da los componentes correctos.
  const localStr = now.toLocaleString("en-GB", {
    timeZone: "Europe/Madrid",
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
  // localStr ej: "Mon, 14:32"
  const m = localStr.match(/^(\w{3}),?\s+(\d{2}):(\d{2})/);
  if (!m) return true; // por seguridad, asumimos en horario
  const dayMap: Record<string, number> = {
    Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6,
  };
  const dow = dayMap[m[1]] ?? 1;
  if (!config.diasLaborables.includes(dow)) return false;
  const hh = Number(m[2]);
  const mn = Number(m[3]);
  const totalMin = hh * 60 + mn;
  const [sh, sm] = config.horarioAtencionInicio.split(":").map(Number);
  const [eh, em] = config.horarioAtencionFin.split(":").map(Number);
  return totalMin >= sh * 60 + sm && totalMin < eh * 60 + em;
}

interface ProximaCita {
  id: string;
  pacienteNombre: string;
  fechaCita: Date;
  profesional: string;
  servicio: string;
  estado: string;
}

interface Patient {
  numeroHistoria: string;
  nombreCompleto: string;
  email: string;
  proteccionDatosFirmada: boolean;
}

// Teléfono de recepción humana — debe ir en config; fallback hardcoded para
// que el filtro Fase 3 funcione aun sin config completa.
const TELEFONO_RECEPCION_FALLBACK = "+34 629 01 10 55";

/**
 * Filtro Fase 3: comprueba si el remitente está registrado en clinni_patients.
 * Si no lo está, el bot evita gastar Claude con el mensaje y responde con un
 * texto fijo redirigiendo a recepción humana. Devuelve null si no encuentra
 * paciente o si Firestore falla (en cuyo caso dejamos pasar para no romper).
 */
async function findPatient(telefono: string): Promise<Patient | null> {
  try {
    const doc = await db.collection("clinni_patients").doc(telefono).get();
    if (!doc.exists) return null;
    const data = doc.data() ?? {};
    return {
      numeroHistoria: (data.numeroHistoria as string) ?? "",
      nombreCompleto: ((data.nombreCompleto as string) ||
                       (data.nombre as string) || "").trim(),
      email: (data.email as string) ?? "",
      proteccionDatosFirmada: data.proteccionDatosFirmada === true,
    };
  } catch (e) {
    functions.logger.warn(
        "findPatient falló — dejamos pasar para no bloquear",
        {telefono, error: String(e)},
    );
    return null;
  }
}

async function findUpcomingAppointment(
    telefono: string,
): Promise<ProximaCita | null> {
  // Tolerante a fallos: si Firestore devuelve error (índice faltante, timeout,
  // permisos), devolvemos null en lugar de propagar la excepción para que el
  // bot al menos pueda responder algo al paciente.
  try {
    const now = admin.firestore.Timestamp.now();
    const snap = await db
        .collection("clinni_appointments")
        .where("pacienteTelefono", "==", telefono)
        .where("fechaCita", ">=", now)
        .where("estado", "in", ["pendiente", "confirmada", "reagendada"])
        .orderBy("fechaCita")
        .limit(1)
        .get();
    if (snap.empty) return null;
    const doc = snap.docs[0];
    const data = doc.data();
    return {
      id: doc.id,
      pacienteNombre: (data.pacienteNombre as string) ?? "",
      fechaCita: (data.fechaCita as admin.firestore.Timestamp).toDate(),
      profesional: (data.profesional as string) ?? "",
      servicio: (data.servicio as string) ?? "",
      estado: (data.estado as string) ?? "pendiente",
    };
  } catch (e) {
    functions.logger.warn(
        "findUpcomingAppointment falló, continuamos sin cita asociada",
        {telefono, error: String(e)},
    );
    return null;
  }
}

interface ConversationDoc {
  id: string;
  data: admin.firestore.DocumentData;
}

async function findActiveConversation(
    telefono: string,
): Promise<ConversationDoc | null> {
  // Idem que findUpcomingAppointment: si Firestore falla devolvemos null para
  // que el bot pueda crear una conversación nueva en lugar de quedarse mudo.
  try {
    const snap = await db
        .collection("whatsapp_conversations")
        .where("pacienteTelefono", "==", telefono)
        .where("estado", "in", [
          "activa",
          "esperando_respuesta_boton",
          "esperando_respuesta_boton_2",
          "esperando_respuesta_boton_reagendar",
        ])
        .orderBy("fechaUltimaInteraccion", "desc")
        .limit(1)
        .get();
    if (snap.empty) return null;
    return {id: snap.docs[0].id, data: snap.docs[0].data()};
  } catch (e) {
    functions.logger.warn(
        "findActiveConversation falló, asumimos sin conversación activa",
        {telefono, error: String(e)},
    );
    return null;
  }
}

async function appendMessageToConversation(
    convId: string,
    rol: "paciente" | "bot",
    texto: string,
    extra: Partial<Record<string, unknown>> = {},
): Promise<void> {
  await db.collection("whatsapp_conversations").doc(convId).update({
    fechaUltimaInteraccion: admin.firestore.FieldValue.serverTimestamp(),
    mensajes: admin.firestore.FieldValue.arrayUnion({
      rol,
      texto,
      timestamp: admin.firestore.Timestamp.now(),
    }),
    ...extra,
  });
}

async function createConversation(params: {
  pacienteNombre: string;
  pacienteTelefono: string;
  appointmentId: string | null;
  tipo: "recordatorio" | "paciente_iniciado";
  profesional: string;
  fechaCita: Date | null;
  textoInicial: string;
  rolInicial: "paciente" | "bot";
}): Promise<string> {
  const ref = await db.collection("whatsapp_conversations").add({
    pacienteNombre: params.pacienteNombre,
    pacienteTelefono: params.pacienteTelefono,
    appointmentId: params.appointmentId,
    tipo: params.tipo,
    estado: "activa",
    intencionDetectada: null,
    resultado: null,
    mensajes: [
      {
        rol: params.rolInicial,
        texto: params.textoInicial,
        timestamp: admin.firestore.Timestamp.now(),
      },
    ],
    fechaCreacion: admin.firestore.FieldValue.serverTimestamp(),
    fechaUltimaInteraccion: admin.firestore.FieldValue.serverTimestamp(),
    gestionadoPor: "bot",
    profesional: params.profesional,
    fechaCita: params.fechaCita ?
      admin.firestore.Timestamp.fromDate(params.fechaCita) :
      null,
  });
  return ref.id;
}

function formatFechaES(date: Date, lang: "es" | "en"): string {
  return date.toLocaleString(lang === "es" ? "es-ES" : "en-GB", {
    timeZone: "Europe/Madrid",
    weekday: "long",
    day: "numeric",
    month: "long",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/**
 * Construye un DM estructurado para enviar a recepción. Aplica una jerarquía
 * visual consistente para que el ojo capte la info de un vistazo:
 *
 *   {ICONO} {TÍTULO EN MAYÚSCULAS}
 *   👤 {nombre}
 *   📞 {telefono}
 *
 *   {bloque opcional de citas / mensaje}
 *
 *   ➡️ {acción concreta para recepción}
 *
 * Usa los iconos consistentemente: ✅ positivo/nuevo, ❌ anterior/cancelado,
 * ⚠️ atención, 🆘 urgencia, 🔄 reagendar, 📨 escalada, 📞 teléfono,
 * 📅 fecha, 💬 mensaje del paciente, ➡️ acción.
 */
function buildRecepcionMsg(opts: {
  icono: string;
  titulo: string;
  nombre?: string;
  telefono: string;
  citaAnterior?: string;
  citaNueva?: string;
  citaActual?: string;
  mensajeOriginal?: string;
  extra?: string[];
  cta?: string;
}): string {
  const lines: string[] = [];
  lines.push(`${opts.icono} ${opts.titulo}`);
  if (opts.nombre) lines.push(`👤 ${opts.nombre}`);
  lines.push(`📞 ${opts.telefono}`);

  const dataLines: string[] = [];
  // Las etiquetas "Cita:", "Cita anterior:", "Cita nueva:" se omiten porque
  // los iconos ya las identifican (📅 actual, ❌ anterior, ✅ nueva). Tipografía
  // más limpia y menos texto que recepción tenga que leer.
  if (opts.citaActual) dataLines.push(`📅 ${opts.citaActual}`);
  if (opts.citaAnterior) dataLines.push(`❌ ${opts.citaAnterior}`);
  if (opts.citaNueva) dataLines.push(`✅ ${opts.citaNueva}`);
  if (opts.mensajeOriginal && !opts.mensajeOriginal.startsWith("(botón:")) {
    dataLines.push(`💬 "${opts.mensajeOriginal}"`);
  }
  for (const e of opts.extra ?? []) dataLines.push(e);
  if (dataLines.length > 0) {
    lines.push("");
    lines.push(...dataLines);
  }

  if (opts.cta) {
    lines.push("");
    lines.push(`➡️ ${opts.cta}`);
  }
  return lines.join("\n");
}

async function notifyRecepcion(
    config: BotConfig,
    token: string,
    mensaje: string,
): Promise<void> {
  if (!config.grupoRecepcionId) {
    functions.logger.warn(
        "grupoRecepcionId no configurado, notificación recepción descartada",
    );
    return;
  }
  functions.logger.info("notifyRecepcion → enviando DM a recepción", {
    to: config.grupoRecepcionId,
    mensajePreview: mensaje.slice(0, 80),
  });
  const r = await sendTextMessage(
      {phoneId: config.whatsappPhoneId, token, to: config.grupoRecepcionId},
      mensaje,
  );
  functions.logger.info("notifyRecepcion sendTextMessage resultado", {
    success: r.success,
    error: r.error,
    messageId: r.messageId,
  });
}

/**
 * Idempotencia: Meta entrega webhooks at-least-once y reintenta hasta 36h.
 * Cada mensaje trae un id único; lo guardamos con TTL para no procesar
 * dos veces. Devuelve true si es el primer procesamiento, false si ya
 * estaba registrado (= duplicado a ignorar).
 */
// ─── Opt-out RGPD ─────────────────────────────────────────────────────────
// Cumplimiento del derecho a no recibir comunicaciones (LSSI / RGPD art. 21).
// Si el paciente envía BAJA / STOP / UNSUBSCRIBE / "no contactar" / similar,
// añadimos su teléfono a whatsapp_optouts y dejamos de procesar sus mensajes.
// Antes de cada mensaje, si el teléfono está en la lista, silenciamos.
const OPT_OUT_KEYWORDS = [
  "baja", "stop", "unsubscribe", "darme de baja", "dar de baja",
  "no quiero recibir", "no me escribáis", "no me contactéis",
  "no contactar", "no me molestes", "no me molestéis",
];

function isOptOutMessage(texto: string): boolean {
  const t = texto.trim().toLowerCase();
  if (t.length === 0 || t.length > 60) return false;
  return OPT_OUT_KEYWORDS.some((kw) => t === kw || t.startsWith(kw + " ") ||
    t.endsWith(" " + kw) || t.includes(" " + kw + " "));
}

async function isOptedOut(telefono: string): Promise<boolean> {
  try {
    const doc = await db.collection("whatsapp_optouts").doc(telefono).get();
    return doc.exists;
  } catch (e) {
    functions.logger.warn("isOptedOut falló — dejamos pasar", {telefono, error: String(e)});
    return false;
  }
}

async function recordOptOut(telefono: string, mensaje: string): Promise<void> {
  await db.collection("whatsapp_optouts").doc(telefono).set({
    telefono,
    fechaBaja: admin.firestore.Timestamp.now(),
    mensajeOriginal: mensaje.slice(0, 200),
  });
}

// ─── Rate limiting ────────────────────────────────────────────────────────
// Defensa anti-abuso: máximo 10 mensajes por teléfono en una ventana de 5 min.
// Si un teléfono supera ese ratio, el bot calla por completo (no responde, no
// llama a Claude, no notifica). Los timestamps antiguos se ignoran por la
// cutoff window así que el bot vuelve a responder cuando baja el ritmo.
const RATE_LIMIT_MAX = 10;
const RATE_LIMIT_WINDOW_MS = 5 * 60 * 1000;

async function checkRateLimit(telefono: string): Promise<boolean> {
  try {
    const ref = db.collection("whatsapp_rate_limit").doc(telefono);
    const now = Date.now();
    const cutoff = now - RATE_LIMIT_WINDOW_MS;

    const doc = await ref.get();
    const stored = doc.exists ?
      ((doc.data()?.timestamps as number[] | undefined) ?? []) :
      [];
    const recent = stored.filter((t) => t > cutoff);

    if (recent.length >= RATE_LIMIT_MAX) {
      functions.logger.warn("Rate limit excedido — silenciando", {
        telefono,
        recentCount: recent.length,
        windowMinutes: RATE_LIMIT_WINDOW_MS / 60000,
        max: RATE_LIMIT_MAX,
      });
      return false;
    }

    recent.push(now);
    await ref.set({
      timestamps: recent,
      lastActivity: admin.firestore.Timestamp.now(),
    });
    return true;
  } catch (e) {
    // Si Firestore falla, dejamos pasar para no bloquear el bot por accidente.
    functions.logger.warn("checkRateLimit falló — dejamos pasar", {
      telefono,
      error: String(e),
    });
    return true;
  }
}

async function claimMessageId(messageId: string): Promise<boolean> {
  if (!messageId) return true; // sin id, dejamos pasar (mejor procesar dos veces que ninguna)
  const ref = db.collection("whatsapp_processed_messages").doc(messageId);
  try {
    await ref.create({
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e: unknown) {
    // ALREADY_EXISTS → mensaje ya procesado
    const code = (e as {code?: number | string}).code;
    if (code === 6 || code === "already-exists") {
      functions.logger.info("Mensaje duplicado ignorado", {messageId});
      return false;
    }
    functions.logger.warn("claimMessageId falló, procesamos por seguridad", e);
    return true;
  }
}

async function processIncomingText(
    telefono: string,
    texto: string,
    waToken: string,
    appSecret: string, // eslint-disable-line @typescript-eslint/no-unused-vars
    anthropicKey: string,
): Promise<void> {
  functions.logger.info("➡️ processIncomingText START", {
    telefono,
    textoPreview: texto.slice(0, 60),
  });

  // Opt-out RGPD: si el teléfono ya está dado de baja, silenciamos.
  if (await isOptedOut(telefono)) {
    functions.logger.info("Teléfono dado de baja, silenciando", {telefono});
    return;
  }

  // Rate limit: bloqueo silencioso si supera el ratio.
  const allowed = await checkRateLimit(telefono);
  if (!allowed) return;

  // Si el mensaje es una solicitud de baja, registramos y respondemos una vez.
  if (isOptOutMessage(texto)) {
    functions.logger.info("Solicitud de baja detectada", {telefono, textoPreview: texto.slice(0, 60)});
    await recordOptOut(telefono, texto);
    const config = await loadConfig();
    await sendTextMessage(
        {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
        "Hecho, has sido dado de baja de los avisos automáticos. " +
        "No volverás a recibir mensajes desde este número. " +
        "Si más adelante quieres volver a recibirlos, escríbenos o llama a recepción 🌿",
    );
    return;
  }

  const config = await loadConfig();
  if (!config.activo) {
    functions.logger.info("Bot inactivo, mensaje ignorado", {telefono});
    return;
  }
  functions.logger.info("config cargada", {
    phoneId: config.whatsappPhoneId,
    activo: config.activo,
    grupoRecepcion: config.grupoRecepcionId ? "SET" : "EMPTY",
  });

  // Paralelizamos las 3 lecturas de Firestore para reducir latencia.
  const [patient, cita, convInicial] = await Promise.all([
    findPatient(telefono),
    findUpcomingAppointment(telefono),
    findActiveConversation(telefono),
  ]);
  functions.logger.info("contexto cargado", {
    patientEncontrado: patient !== null,
    pacienteHistoria: patient?.numeroHistoria,
    citaEncontrada: cita !== null,
    citaId: cita?.id,
    convEncontrada: convInicial !== null,
    convId: convInicial?.id,
  });

  // ─── Fase 3: filtro de paciente conocido ──────────────────────────────────
  // Si el remitente no está registrado como paciente Y no tiene cita asociada,
  // respondemos con texto fijo redirigiendo a recepción humana, SIN llamar a
  // Claude (ahorra tokens y bloquea spam). Solo aplica si la conversación es
  // nueva (sin historial activo): si ya hay conversación activa, dejamos pasar
  // para no cortar un hilo en curso.
  if (!patient && !cita && !convInicial) {
    functions.logger.info(
        "📛 Filtro Fase 3 — paciente no registrado, no se invoca Claude",
        {telefono},
    );
    const fechaPos = (await db.collection("config").doc("whatsapp_bot").get())
        .data();
    const telRecepcion = (fechaPos?.telefonoRecepcion as string) ||
                         TELEFONO_RECEPCION_FALLBACK;
    const respuestaFija =
      "¡Hola! 👋 Te escribe el bot del Centro Salufit. " +
      "No te encuentro como paciente en nuestra base de datos. " +
      "Para pedir información, una cita o resolver cualquier duda, " +
      `puedes llamarnos al ${telRecepcion} y te atendemos al momento.`;
    await sendTextMessage(
        {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
        respuestaFija,
    );
    // Registramos la conversación para auditoría/futuro filtrado, marcada
    // explícitamente como no_registrado para que el panel admin la vea aparte.
    await createConversation({
      pacienteNombre: "(no registrado)",
      pacienteTelefono: telefono,
      appointmentId: null,
      tipo: "paciente_iniciado",
      profesional: "",
      fechaCita: null,
      textoInicial: texto,
      rolInicial: "paciente",
    }).then((convId) =>
      db.collection("whatsapp_conversations").doc(convId).update({
        estado: "no_registrado",
        resultado: "filtrado_no_paciente",
        intencionDetectada: "filtered",
        mensajes: admin.firestore.FieldValue.arrayUnion({
          rol: "bot",
          texto: respuestaFija,
          timestamp: admin.firestore.Timestamp.now(),
        }),
      }),
    );
    // Notificación opcional a recepción para que sepa que un desconocido escribió.
    await notifyRecepcion(config, waToken, buildRecepcionMsg({
      icono: "🔕",
      titulo: "NÚMERO NO REGISTRADO (filtrado)",
      telefono,
      mensajeOriginal: texto.slice(0, 200),
      cta: "Bot redirigió al teléfono de recepción. Valorar si es un lead nuevo y crear ficha en CRM.",
    }));
    return;
  }

  // ─── Continuamos con el flujo normal (paciente conocido o conversación activa) ──
  let conv = convInicial;
  // Si el usuario inicia conversación sin cita asociada, intentar reagendar/escalar igualmente
  if (!conv) {
    const convId = await createConversation({
      pacienteNombre:
        patient?.nombreCompleto ||
        cita?.pacienteNombre ||
        "(sin registrar)",
      pacienteTelefono: telefono,
      appointmentId: cita?.id ?? null,
      tipo: "paciente_iniciado",
      profesional: cita?.profesional ?? "",
      fechaCita: cita?.fechaCita ?? null,
      textoInicial: texto,
      rolInicial: "paciente",
    });
    conv = {id: convId, data: {}};
  } else {
    await appendMessageToConversation(conv.id, "paciente", texto);
  }

  const inHours = isWithinBusinessHours(new Date(), config);

  // ─── Gate fuera de horario ────────────────────────────────────────────────
  // Cuando el mensaje entra fuera de L-V 09:00-20:00 (configurable), NO
  // llamamos a Claude. Enviamos un aviso fijo una sola vez por conversación
  // y dejamos que recepción atienda manualmente cuando abra. Evita molestar
  // al cliente con respuestas elaboradas en madrugada y ahorra tokens.
  if (!inHours) {
    const yaAvisado = conv.data?.outOfHoursAvisado === true;
    if (!yaAvisado) {
      const aviso =
        "¡Hola! 👋 Hemos recibido tu mensaje fuera de horario " +
        "(atendemos de lunes a viernes, 9:00–20:00). Tranquilo, lo dejamos " +
        "anotado y recepción te contesta en cuanto abramos.";
      functions.logger.info(
          "Fuera de horario — enviando aviso único",
          {telefono, convId: conv.id},
      );
      const r = await sendTextMessage(
          {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
          aviso,
      );
      functions.logger.info("aviso fuera de horario sendTextMessage resultado", {
        success: r.success,
        messageId: r.messageId,
        error: r.error,
      });
      // Mantenemos la conv en estado "activa" para que findActiveConversation
      // la siga encontrando en mensajes posteriores y silencie correctamente.
      // Recepción la cerrará manualmente al atenderla por la mañana.
      await db.collection("whatsapp_conversations").doc(conv.id).update({
        outOfHoursAvisado: true,
        intencionDetectada: "fuera_horario",
        fechaUltimaInteraccion: admin.firestore.Timestamp.now(),
        mensajes: admin.firestore.FieldValue.arrayUnion({
          rol: "bot",
          texto: aviso,
          timestamp: admin.firestore.Timestamp.now(),
        }),
      });
    } else {
      functions.logger.info(
          "Fuera de horario — aviso ya enviado, silenciando",
          {telefono, convId: conv.id},
      );
      // Solo dejamos rastro en logs; el mensaje del paciente ya fue
      // registrado al crear/actualizar la conversación más arriba.
    }
    return;
  }

  const horasHastaCita = cita ?
    (cita.fechaCita.getTime() - Date.now()) / (1000 * 60 * 60) :
    Number.POSITIVE_INFINITY;

  // Historial reciente para multi-turno: últimos 6 mensajes de la conv,
  // EXCLUYENDO el mensaje actual del paciente (ya se pasa como user input).
  // Si la conv es nueva (textoInicial), no hay historial previo relevante.
  const todosMensajes =
    (conv.data?.mensajes as Array<{rol: "paciente" | "bot"; texto: string}> | undefined) ??
    [];
  const historialMensajes = todosMensajes
      .filter((m) => m.rol === "paciente" || m.rol === "bot")
      .slice(-7, -1) // los 6 anteriores al actual
      .map((m) => ({rol: m.rol, texto: m.texto}));

  functions.logger.info("Llamando a Claude para clasificar...", {
    textoPreview: texto.slice(0, 60),
    historialCount: historialMensajes.length,
  });
  const classification = await classifyIntent(anthropicKey, texto, {
    // Preferimos el nombre de la cita (más reciente) sobre el del listado de
    // pacientes; si no hay cita, usamos el paciente registrado.
    pacienteNombre:
      cita?.pacienteNombre ||
      patient?.nombreCompleto ||
      "",
    fechaCita: cita ? cita.fechaCita.toISOString() : "",
    profesional: cita?.profesional ?? "",
    servicio: cita?.servicio ?? "",
    isWithinBusinessHours: inHours,
    horasHastaCita,
    historialMensajes,
  });
  functions.logger.info("Claude resultado", {
    classification: classification ? {
      intencion: classification.intencion,
      idioma: classification.idiomaDetectado,
      respuestaPreview: classification.respuesta.slice(0, 80),
    } : null,
  });

  if (!classification) {
    // Fallback genérico si la IA falla
    const textoFallback =
      "Gracias por tu mensaje. Te contactaremos desde recepción en breve.";
    functions.logger.info("Enviando fallback IA al paciente...", {
      phoneId: config.whatsappPhoneId,
      to: telefono,
    });
    const fallbackResult = await sendTextMessage(
        {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
        textoFallback,
    );
    functions.logger.info("sendTextMessage fallback resultado", {
      success: fallbackResult.success,
      error: fallbackResult.error,
      messageId: fallbackResult.messageId,
    });
    await appendMessageToConversation(
        conv.id,
        "bot",
        "(fallback IA) Gracias por tu mensaje. Te contactaremos desde recepción.",
        {
          estado: fallbackResult.success ? "escalada" : "error_envio_fallback",
          intencionDetectada: "escalate",
        },
    );
    await notifyRecepcion(config, waToken, buildRecepcionMsg({
      icono: "⚠️",
      titulo: "BOT FALLBACK (IA caída)",
      nombre: patient?.nombreCompleto || cita?.pacienteNombre,
      telefono,
      mensajeOriginal: texto,
      cta: fallbackResult.success ?
        "IA no disponible. Bot envió acuse genérico al paciente. Atender manualmente." :
        `IA no disponible Y envío fallback FALLÓ (${fallbackResult.error ?? "?"}). Atender con urgencia.`,
    }));
    return;
  }

  // Enviar respuesta breve al paciente.
  // Excepción: para intent="reagendar", el case correspondiente del switch en
  // executeAction enviará un único mensaje completo (saludo + slots concretos
  // o saludo + acuse de escalada). Si enviamos también el texto de Claude
  // antes, generamos redundancia y exponemos posibles alucinaciones de hora /
  // profesional. Para el resto de intenciones, el texto de Claude es el
  // mensaje principal (la lógica de executeAction es solo persistencia).
  const skipClaudeMessage = classification.intencion === "reagendar";
  if (!skipClaudeMessage) {
    functions.logger.info("Enviando respuesta a paciente...", {
      phoneId: config.whatsappPhoneId,
      to: telefono,
    });
    const sendResult = await sendTextMessage(
        {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
        classification.respuesta,
    );
    functions.logger.info("sendTextMessage resultado", {
      success: sendResult.success,
      error: sendResult.error,
      messageId: sendResult.messageId,
    });
  } else {
    functions.logger.info(
        "Mensaje de Claude suprimido (intent=reagendar) — case enviará bloque único",
        {convId: conv.id},
    );
  }
  // Persistimos la respuesta de Claude en la conv aunque no la enviemos al
  // paciente (sirve de auditoría + multi-turno). El campo `noEnviado:true`
  // marca que ese texto NO se mandó por WhatsApp.
  await appendMessageToConversation(conv.id, "bot", classification.respuesta, {
    intencionDetectada: classification.intencion,
    idiomaDetectado: classification.idiomaDetectado,
    dentro48h: classification.dentro48h,
    fuerzaMayor: classification.fuerzaMayor,
    ...(skipClaudeMessage ? {claudeMessageSuppressed: true} : {}),
  });

  // Ejecutar acción según intención
  await executeAction(
      classification.intencion,
      classification.idiomaDetectado,
      classification.dentro48h,
      classification.fuerzaMayor,
      conv.id,
      cita,
      telefono,
      texto,
      config,
      waToken,
      patient?.nombreCompleto || cita?.pacienteNombre || telefono,
  );
}

async function executeAction(
    intent: BotIntent,
    lang: "es" | "en",
    dentro48h: boolean,
    fuerzaMayor: boolean,
    convId: string,
    cita: ProximaCita | null,
    telefono: string,
    mensajeOriginal: string,
    config: BotConfig,
    waToken: string,
    pacienteNombre: string,
): Promise<void> {
  switch (intent) {
    case "confirmar":
      if (cita) {
        await db
            .collection("clinni_appointments")
            .doc(cita.id)
            .update({estado: "confirmada"});
        const fechaFmt = formatFechaES(cita.fechaCita, lang);
        const msg = lang === "en" ?
          `Perfect, your appointment on ${fechaFmt} with ${cita.profesional} is confirmed. See you soon!` :
          `Perfecto, tu cita del ${fechaFmt} con ${cita.profesional} queda confirmada. ¡Te esperamos!`;
        await sendTextMessage(
            {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
            msg,
        );
        await appendMessageToConversation(convId, "bot", msg, {
          estado: "resuelta",
          resultado: "cita_confirmada",
        });
      } else {
        await appendMessageToConversation(convId, "bot", "(sin cita asociada)", {
          estado: "escalada",
          resultado: "confirmar_sin_cita",
        });
        await notifyRecepcion(config, waToken, buildRecepcionMsg({
          icono: "❓",
          titulo: "CONFIRMACIÓN SIN CITA REGISTRADA",
          nombre: pacienteNombre,
          telefono,
          mensajeOriginal,
          cta: "El paciente quiere confirmar pero no tiene cita futura en clinni_appointments. Verificar.",
        }));
      }
      return;

    case "cancelar":
      if (cita && dentro48h) {
        // POLÍTICA 48h: NO cancelamos automáticamente. Si viene de botón
        // (Claude no respondió antes), enviamos mensaje con la política
        // y, en cancelaciones SIN fuerza mayor, también ofrecemos slots de
        // reagendación dentro de las 48h siguientes a la cita actual para
        // que el paciente pueda tomar la decisión rápido sin esperar a
        // recepción.
        const vieneDeBoton = mensajeOriginal.startsWith("(botón:");
        const saludoNombreCancel = pacienteNombre.split(" ")[0] || "";

        if (vieneDeBoton) {
          // Texto rediseñado aplicando principios de behavioral economics
          // (loss aversion, default option, reciprocity, reframing positivo).
          // Ver auditoría en CLAUDE.md o commit feat(bot): nudge cancelación
          // dentro 48h.
          const msgPol = fuerzaMayor ?
            `Hola${saludoNombreCancel ? " " + saludoNombreCancel : ""} 🙏 ` +
            "Sentimos lo que está pasando. Recepción te llamará enseguida " +
            "para ayudarte y darle prioridad a tu caso." :
            `Hola${saludoNombreCancel ? " " + saludoNombreCancel : ""} 👋 ` +
            "Gracias por avisarnos a tiempo.\n\n" +
            "Tu hueco está reservado para ti y queda menos de 48h. " +
            "Para que no se pierda podemos hacer dos cosas:\n\n" +
            "✅ Cambiarlo gratis dentro de las próximas 48h\n" +
            "   (justo debajo te paso los huecos libres 👇)\n\n" +
            "💳 O, si no te encaja ninguno, cerrar la cita con una\n" +
            "   aportación de 55 € por Bizum al +34 629 01 10 55.\n\n" +
            "Lo más cómodo suele ser lo primero, échales un ojo 🙂";
          await sendTextMessage(
              {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
              msgPol,
          );
        }

        // En fuerza mayor NO ofrecemos slots — escalada limpia para Alba.
        // En cancelación normal dentro de 48h sí intentamos ofrecer slots
        // dentro de la ventana 48h-after-cita para acelerar el reagendado.
        let slotsOfrecidosCancel: Slot[] = [];
        if (vieneDeBoton && !fuerzaMayor) {
          const restrict = cita.fechaCita.getTime() + 48 * 60 * 60 * 1000;
          const primerIntentoCancel = await findNextAvailableSlots(
              cita.profesional,
              {
                count: 2,
                bufferMinutosDesdeAhora: 60,
                diasVista: 14,
                restrictToBeforeMs: restrict,
                // Solo slots POSTERIORES a la cita actual — la regla 48h dice
                // "dentro de las 48h SIGUIENTES" (no anteriores).
                restrictToAfterMs: cita.fechaCita.getTime(),
              },
          );
          const schedule = primerIntentoCancel.schedule;
          let slots = primerIntentoCancel.slots;
          // Opción B: si dentro 48h no hay slots, ampliamos a 14 días vista.
          let slotsFueraDe48hCancel = false;
          if (slots.length === 0 && schedule && schedule.activo &&
              !schedule.escalaDirectaParaReagendar) {
            const segundo = await findNextAvailableSlots(cita.profesional, {
              count: 2,
              bufferMinutosDesdeAhora: 60,
              diasVista: 14,
              restrictToAfterMs: cita.fechaCita.getTime(),
              // sin restrictToBeforeMs → 14 días por defecto
            });
            if (segundo.slots.length > 0) {
              slots = segundo.slots;
              slotsFueraDe48hCancel = true;
              functions.logger.info(
                  "Cancelar+48h: 0 slots en 48h, ampliando ventana 14 días",
                  {convId, slotsFallback: segundo.slots.length},
              );
            }
          }
          if (schedule && schedule.activo &&
              !schedule.escalaDirectaParaReagendar && slots.length > 0) {
            slotsOfrecidosCancel = slots;
            const detalleTextos = slots
                .map((s, i) => `${i + 1}. ${longLabelForSlot(s)}`)
                .join("\n");
            const body = slotsFueraDe48hCancel ?
              "Dentro del plazo de 48h no tenemos huecos. Te proponemos las " +
              "primeras alternativas más allá del plazo:\n\n" +
              `${detalleTextos}\n\n` +
              "Si te encaja alguno, pulsa el horario y recepción se pondrá " +
              "en contacto contigo para confirmarlo (al estar fuera del " +
              "plazo, valorarán si se aplica nuestra política de cancelación " +
              "o si lo gestionamos como caso especial). Si prefieres pagar " +
              "los 55€ por Bizum, pulsa \"Otro horario\"." :
              "Estos son los huecos que tenemos disponibles para ti:\n\n" +
              `${detalleTextos}\n\n` +
              "Pulsa el que mejor te encaje. Si ninguno te viene bien o " +
              "prefieres la opción del Bizum, pulsa \"Otro horario\" y " +
              "recepción se pone en contacto contigo.";
            const botones = [
              ...slots.map((s, i) => ({
                id: `slot_${convId}_${i}`,
                title: shortLabelForSlot(s),
              })),
              {id: "slot_other", title: "Otro horario"},
            ].slice(0, 3);
            const r = await sendButtonMessage(
                {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
                body,
                botones,
            );
            functions.logger.info("Cancelar+48h — botones de slots enviados", {
              convId, success: r.success, slotsCount: slots.length,
            });
            const slotsParaGuardar = slots.map((s) => ({
              inicio: admin.firestore.Timestamp.fromDate(s.inicio),
              fin: admin.firestore.Timestamp.fromDate(s.fin),
              profesionalId: s.profesionalId,
              profesionalNombre: s.profesionalNombre,
            }));
            await db.collection("whatsapp_conversations").doc(convId).update({
              estado: "esperando_respuesta_boton_reagendar",
              intencionDetectada: "reagendar",
              origenReagendar: "cancelacion_dentro_48h",
              slotsOfrecidos: slotsParaGuardar,
              slotsFueraDePlazo: slotsFueraDe48hCancel,
              fechaUltimaInteraccion: admin.firestore.Timestamp.now(),
              mensajes: admin.firestore.FieldValue.arrayUnion({
                rol: "bot",
                texto: body,
                timestamp: admin.firestore.Timestamp.now(),
              }),
            });
          } else {
            functions.logger.info(
                "Cancelar+48h — sin slots para ofrecer, solo escalada",
                {convId, motivo: !schedule ? "sin schedule" :
                  !schedule.activo ? "inactivo" :
                    schedule.escalaDirectaParaReagendar ? "escalaDirecta" :
                      "0 slots en ventana 48h"},
            );
          }
        }

        const resultado = fuerzaMayor ?
          "cancelar_dentro_48h_fuerza_mayor" :
          slotsOfrecidosCancel.length > 0 ?
            "cancelar_dentro_48h_slots_ofrecidos" :
            "cancelar_dentro_48h_escalado";
        if (slotsOfrecidosCancel.length === 0) {
          // Solo persistimos un mensaje genérico si no hubo slots — si
          // hubo, el update de la conv ya añadió el body de slots.
          await appendMessageToConversation(convId, "bot",
              "(cancelación dentro de 48h, decisión recepción)", {
                estado: "cancelacion_solicitada",
                resultado,
              });
        }
        // Si el bot ofreció slots al paciente, NO notificamos a recepción
        // ahora — el paciente está en mitad del flujo y aún no decidió. Si
        // pulsa un slot, processInteractiveReply mandará "✅ REAGENDACIÓN
        // SOLICITADA"; si pulsa "Otro horario", el handler de slot_other
        // mandará otro DM; si abandona, checkConversationTimeouts escalará.
        // Evita ruido de mensajes a recepción.
        if (slotsOfrecidosCancel.length === 0) {
          const icono = fuerzaMayor ? "🆘" : "⚠️";
          const titulo = fuerzaMayor ?
            "[ALBA] CANCELACIÓN <48h — FUERZA MAYOR" :
            "[ALBA] CANCELACIÓN DENTRO DE 48h";
          const cta = fuerzaMayor ?
            "Paciente alega fuerza mayor — valorar exención. Si no procede, ofrecer reagendar +48h o 55€ Bizum." :
            "Política 48h aplicada. Decisión humana: reagendar +48h máx 2 veces o cobrar 55€ Bizum.";
          await notifyRecepcion(config, waToken, buildRecepcionMsg({
            icono,
            titulo,
            nombre: cita.pacienteNombre,
            telefono,
            citaActual: `${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}`,
            mensajeOriginal,
            cta,
          }));
        }
      } else if (cita) {
        // Cancelación con más de 48h de antelación: gratuita.
        await db
            .collection("clinni_appointments")
            .doc(cita.id)
            .update({estado: "cancelada"});
        const fechaFmt = formatFechaES(cita.fechaCita, lang);
        const msg = lang === "en" ?
          `Your appointment on ${fechaFmt} has been cancelled. Contact us to book a new one.` :
          `Tu cita del ${fechaFmt} ha sido cancelada. Contáctanos cuando quieras reservar una nueva.`;
        await sendTextMessage(
            {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
            msg,
        );
        await appendMessageToConversation(convId, "bot", msg, {
          estado: "resuelta",
          resultado: "cita_cancelada",
        });
        await notifyRecepcion(config, waToken, buildRecepcionMsg({
          icono: "❌",
          titulo: "CITA CANCELADA (gratuita >48h)",
          nombre: cita.pacienteNombre,
          telefono,
          citaActual: `${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}`,
          cta: "Bot ya marcó la cita como cancelada en clinni_appointments. Sincronizar con Clinni manualmente si procede.",
        }));
      } else {
        await notifyRecepcion(config, waToken, buildRecepcionMsg({
          icono: "❓",
          titulo: "CANCELACIÓN SIN CITA REGISTRADA",
          telefono,
          mensajeOriginal,
          cta: "El paciente quiere cancelar pero no tiene cita futura en clinni_appointments. Verificar.",
        }));
      }
      return;

    case "reagendar": {
      // FASE 2: búsqueda automática de huecos del MISMO profesional + botones.
      //
      // Si no hay cita asociada, no hay profesional desde el que buscar →
      // escalamos. Si el profesional tiene escalaDirectaParaReagendar=true
      // (odontología, Estela, Andressa) o no está activo → escalamos.
      // Si encuentra ≥1 slot libre, ofrecemos como botones interactivos.

      const saludoNombre = pacienteNombre.split(" ")[0] || "";
      if (!cita) {
        const msgPaciente =
          `Hola${saludoNombre ? " " + saludoNombre : ""} 👋 ` +
          "Mensaje recibido. Recepción te llamará enseguida para mirar " +
          "el cambio contigo 🙂";
        await sendTextMessage(
            {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
            msgPaciente,
        );
        await appendMessageToConversation(convId, "bot", msgPaciente, {
          estado: "reagendar_solicitada",
          resultado: "reagendar_sin_cita",
        });
        await notifyRecepcion(config, waToken, buildRecepcionMsg({
          icono: "🔄",
          titulo: "REAGENDACIÓN SIN CITA REGISTRADA",
          nombre: pacienteNombre,
          telefono,
          mensajeOriginal,
          cta: "El paciente quiere reagendar pero no tiene cita futura en clinni_appointments. Verificar y gestionar manualmente.",
        }));
        return;
      }

      // Si dentro48h: la nueva cita debe estar dentro de las 48h SIGUIENTES
      // a la cita actual (regla negocio). Por tanto cota inferior=cita.fechaCita
      // y cota superior=cita.fechaCita+48h. Si está fuera de 48h, no aplica
      // ni una ni otra; búsqueda libre en los próximos 14 días.
      const restrictToBeforeMs = dentro48h ?
        cita.fechaCita.getTime() + 48 * 60 * 60 * 1000 :
        undefined;
      const restrictToAfterMs = dentro48h ?
        cita.fechaCita.getTime() :
        undefined;

      const primerIntento = await findNextAvailableSlots(cita.profesional, {
        count: 2,
        bufferMinutosDesdeAhora: 60,
        diasVista: 14,
        restrictToBeforeMs,
        restrictToAfterMs,
      });
      const schedule = primerIntento.schedule;
      let slots = primerIntento.slots;
      // Opción B (decisión 2026-04-30): si dentro48h Y no hay slots en
      // ventana 48h estricta, ampliamos búsqueda a 14 días vista (sin
      // restrictToBeforeMs) para no obligar a recepción a gestionar a
      // mano. El mensaje al cliente avisa explícitamente que esos huecos
      // están fuera del plazo de 48h y recepción decidirá si aplica
      // política (55€) o lo gestiona como caso especial.
      let slotsFueraDe48h = false;
      if (dentro48h && slots.length === 0 && primerIntento.schedule &&
          primerIntento.schedule.activo &&
          !primerIntento.schedule.escalaDirectaParaReagendar) {
        const segundoIntento = await findNextAvailableSlots(cita.profesional, {
          count: 2,
          bufferMinutosDesdeAhora: 60,
          diasVista: 14,
          restrictToAfterMs: cita.fechaCita.getTime(),
          // sin restrictToBeforeMs → busca en toda la ventana de 14 días
        });
        if (segundoIntento.slots.length > 0) {
          slots = segundoIntento.slots;
          slotsFueraDe48h = true;
          functions.logger.info(
              "Reagendar: 0 slots en 48h, ampliando ventana 14 días",
              {convId, slotsFallback: segundoIntento.slots.length},
          );
        }
      }

      // Profesional no encontrado, inactivo o configurado para escalar siempre.
      if (!schedule || !schedule.activo || schedule.escalaDirectaParaReagendar) {
        const motivo = !schedule ? "no encontrado en professional_schedules" :
          !schedule.activo ? "inactivo" :
            schedule.motivoEscalaDirecta ?? "escalada directa configurada";
        const msgPaciente =
          `Hola${saludoNombre ? " " + saludoNombre : ""} 👋 ` +
          "Mensaje recibido. Recepción te contacta enseguida para " +
          "ver el cambio contigo 🙂";
        await sendTextMessage(
            {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
            msgPaciente,
        );
        await appendMessageToConversation(convId, "bot", msgPaciente, {
          estado: "reagendar_solicitada",
          resultado: "reagendar_escalado_recepcion",
          motivoEscalada: motivo,
        });
        await notifyRecepcion(config, waToken, buildRecepcionMsg({
          icono: "🔄",
          titulo: "REAGENDACIÓN MANUAL",
          nombre: pacienteNombre,
          telefono,
          citaActual: `${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}`,
          mensajeOriginal,
          cta: `Profesional ${motivo}; recepción gestiona manualmente.`,
        }));
        return;
      }

      // Sin huecos en la ventana → escalar.
      if (slots.length === 0) {
        const msgPaciente =
          `Hola${saludoNombre ? " " + saludoNombre : ""} 👋 ` +
          (dentro48h ?
            "Como tu cita está muy cerca, prefiero que recepción te llame " +
            "directamente para buscar un hueco que te encaje 🙂" :
            "Recepción te llama enseguida para buscarte un hueco que te venga bien 🙂");
        await sendTextMessage(
            {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
            msgPaciente,
        );
        await appendMessageToConversation(convId, "bot", msgPaciente, {
          estado: "reagendar_solicitada",
          resultado: "reagendar_sin_huecos",
        });
        await notifyRecepcion(config, waToken, buildRecepcionMsg({
          icono: "🔄",
          titulo: "REAGENDACIÓN SIN HUECOS AUTOMÁTICOS",
          nombre: pacienteNombre,
          telefono,
          citaActual: `${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}`,
          cta: dentro48h ?
            "Bot dentro de ventana 48h sin slots libres. Buscar hueco manualmente o gestionar pago 55€ Bizum." :
            "Ventana de 14 días vista vacía. Buscar hueco manualmente o ampliar agenda.",
        }));
        return;
      }

      // Hueco(s) encontrado(s). Construimos botones (max 3 en WhatsApp).
      const slotsParaGuardar = slots.map((s) => ({
        inicio: admin.firestore.Timestamp.fromDate(s.inicio),
        fin: admin.firestore.Timestamp.fromDate(s.fin),
        profesionalId: s.profesionalId,
        profesionalNombre: s.profesionalNombre,
      }));
      const detalleTextos = slots
          .map((s, i) => `${i + 1}. ${longLabelForSlot(s)}`)
          .join("\n");
      // Opción B (decidida con el usuario 2026-04-30): NO mencionamos al
      // profesional concreto en el mensaje al cliente. Si pulsa slot, recepción
      // confirma a quién le toca; si pulsa "Otro horario", recepción puede
      // ofrecer otro fisio sin que el cliente espere al original.
      const body = slotsFueraDe48h ?
        `Hola${saludoNombre ? " " + saludoNombre : ""}, dentro del plazo de ` +
        "48h no tenemos huecos disponibles. Te proponemos las primeras " +
        "alternativas más allá de ese plazo:\n\n" +
        `${detalleTextos}\n\n` +
        "Si te encaja alguno, pulsa el horario y recepción se pondrá en " +
        "contacto contigo para confirmar (al estar fuera del plazo de 48h, " +
        "valorarán si se aplica nuestra política o si lo gestionamos como " +
        "caso especial). Si prefieres otra opción, pulsa \"Otro horario\"." :
        `Hola${saludoNombre ? " " + saludoNombre : ""}, ` +
        "te mostramos los huecos disponibles para reagendar tu cita:\n\n" +
        `${detalleTextos}\n\n` +
        "Pulsa el horario que prefieras o \"Otro horario\" si ninguno te conviene.";
      const botones = [
        ...slots.map((s, i) => ({
          id: `slot_${convId}_${i}`,
          title: shortLabelForSlot(s),
        })),
        {id: "slot_other", title: "Otro horario"},
      ].slice(0, 3);

      const r = await sendButtonMessage(
          {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
          body,
          botones,
      );
      functions.logger.info("Reagendar — botones de slots enviados", {
        convId, success: r.success, error: r.error, slotsCount: slots.length,
      });

      await db.collection("whatsapp_conversations").doc(convId).update({
        estado: "esperando_respuesta_boton_reagendar",
        intencionDetectada: "reagendar",
        slotsOfrecidos: slotsParaGuardar,
        slotsFueraDePlazo: slotsFueraDe48h,
        fechaUltimaInteraccion: admin.firestore.Timestamp.now(),
        mensajes: admin.firestore.FieldValue.arrayUnion({
          rol: "bot",
          texto: body,
          timestamp: admin.firestore.Timestamp.now(),
        }),
      });
      return;
    }

    case "consulta":
      // La respuesta ya se envió en classifyIntent. Marcar como consulta pendiente.
      // (No la cerramos como "resuelta" porque puede que recepción quiera revisarla.)
      await db
          .collection("whatsapp_conversations")
          .doc(convId)
          .update({estado: "consulta_pendiente", resultado: "consulta_respondida"});
      return;

    case "escalate":
      await db
          .collection("whatsapp_conversations")
          .doc(convId)
          .update({estado: "escalada", resultado: "escalado_a_recepcion"});
      await notifyRecepcion(config, waToken, buildRecepcionMsg({
        icono: "📨",
        titulo: "ESCALADO A HUMANO",
        nombre: pacienteNombre,
        telefono,
        mensajeOriginal,
        cta: "Atender personalmente — el paciente solicitó hablar con una persona.",
      }));
      return;

    case "fuera_horario":
      // La respuesta ya indicó horario; nada extra.
      await db
          .collection("whatsapp_conversations")
          .doc(convId)
          .update({estado: "resuelta", resultado: "fuera_horario"});
      return;
  }
}

async function processInteractiveReply(
    telefono: string,
    buttonId: string,
    waToken: string,
    config: BotConfig,
): Promise<void> {
  const conv = await findActiveConversation(telefono);
  const cita = await findUpcomingAppointment(telefono);

  // FASE 2: botones de selección de slot. ID con forma "slot_<convId>_<idx>"
  // o el comodín "slot_other". El convId del id debe coincidir con la conv
  // activa (defensa contra usuarios pulsando botones viejos de otra conv).
  if (buttonId.startsWith("slot_")) {
    if (buttonId === "slot_other") {
      // Paciente pide otro horario → escalamos a recepción.
      const convId = conv?.id ?? null;
      if (convId) {
        await db.collection("whatsapp_conversations").doc(convId).update({
          estado: "escalada",
          resultado: "reagendar_otro_horario",
          fechaUltimaInteraccion: admin.firestore.Timestamp.now(),
        });
        await appendMessageToConversation(convId, "paciente", "(botón: Otro horario)");
      }
      await sendTextMessage(
          {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
          "Entendido 🙂 Recepción te llama enseguida para buscarte un hueco que te venga mejor.",
      );
      await notifyRecepcion(config, waToken, buildRecepcionMsg({
        icono: "🔄",
        titulo: "REAGENDACIÓN — \"OTRO HORARIO\"",
        nombre: cita?.pacienteNombre || conv?.data?.pacienteNombre as string | undefined,
        telefono,
        citaActual: cita ?
          `${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}` :
          undefined,
        cta: "Buscar hueco manualmente. El paciente NO espera profesional concreto: si la franja que pida no encaja con su profesional habitual, se puede ofrecer otro fisio del mismo servicio.",
      }));
      return;
    }

    // slot_<convId>_<idx>
    const m = buttonId.match(/^slot_(.+)_(\d+)$/);
    if (!m) {
      functions.logger.warn("Botón slot con formato inesperado", {buttonId});
      return;
    }
    const buttonConvId = m[1];
    const idx = Number(m[2]);
    if (!conv || conv.id !== buttonConvId) {
      functions.logger.warn("Botón slot apunta a conv distinta de la activa", {
        buttonId, activaId: conv?.id, esperada: buttonConvId,
      });
      await sendTextMessage(
          {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
          "Ese horario ya no está vigente. Por favor escríbenos de nuevo y te buscamos uno actualizado.",
      );
      return;
    }

    const slots = (conv.data?.slotsOfrecidos as Array<{
      inicio: admin.firestore.Timestamp;
      fin: admin.firestore.Timestamp;
      profesionalId: string;
      profesionalNombre: string;
    }> | undefined) ?? [];
    const slot = slots[idx];
    if (!slot) {
      functions.logger.warn("Slot fuera de rango", {buttonId, idx, count: slots.length});
      await sendTextMessage(
          {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
          "No encontré ese horario en tu propuesta. Recepción te contactará.",
      );
      await notifyRecepcion(config, waToken, buildRecepcionMsg({
        icono: "⚠️",
        titulo: "BOTÓN SLOT FUERA DE RANGO",
        telefono,
        cta: `El paciente pulsó botón ${buttonId} pero el slot[${idx}] no existe (count=${slots.length}). Posible bug; atender al paciente y reportar.`,
      }));
      return;
    }

    const inicio = slot.inicio.toDate();
    const fechaTexto = inicio.toLocaleString("es-ES", {
      timeZone: "Europe/Madrid",
      weekday: "long",
      day: "numeric",
      month: "long",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });

    // Confirmamos al paciente y pedimos a recepción que actualice Clinni.
    // (No tocamos clinni_appointments aquí porque el bot no es la fuente de
    //  verdad: la cita real vive en Clinni y se sincroniza por Excel diario.)
    // Opción B: no mencionamos al profesional al cliente para que recepción
    // tenga libertad de reasignar si el slot acaba siendo con otro.
    await sendTextMessage(
        {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
        `¡Listo! Te apuntamos para el ${fechaTexto} 🙂 ` +
        "Recepción te confirma el cambio en breve.",
    );
    await db.collection("whatsapp_conversations").doc(conv.id).update({
      estado: "reagendar_confirmacion_pendiente",
      resultado: "reagendar_slot_seleccionado",
      slotSeleccionado: {
        inicio: slot.inicio,
        fin: slot.fin,
        profesionalId: slot.profesionalId,
        profesionalNombre: slot.profesionalNombre,
      },
      fechaUltimaInteraccion: admin.firestore.Timestamp.now(),
      mensajes: admin.firestore.FieldValue.arrayUnion({
        rol: "paciente",
        texto: `(botón slot: ${fechaTexto} con ${slot.profesionalNombre})`,
        timestamp: admin.firestore.Timestamp.now(),
      }),
    });
    const fueraDePlazo = conv?.data?.slotsFueraDePlazo === true;
    await notifyRecepcion(config, waToken, buildRecepcionMsg({
      icono: fueraDePlazo ? "⚠️" : "✅",
      titulo: fueraDePlazo ?
        "REAGENDACIÓN SOLICITADA — FUERA DE PLAZO 48h" :
        "REAGENDACIÓN SOLICITADA",
      nombre: cita?.pacienteNombre || conv?.data?.pacienteNombre as string | undefined,
      telefono,
      citaAnterior: cita ?
        `${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}` :
        undefined,
      citaNueva: `${fechaTexto} con ${slot.profesionalNombre}`,
      cta: fueraDePlazo ?
        "El bot ofreció esta alternativa fuera del plazo de 48h porque no había huecos dentro. Decide si aplica política (55€) o caso especial." :
        undefined,
    }));
    return;
  }

  let intent: BotIntent | null = null;
  if (buttonId === "btn_confirm") intent = "confirmar";
  else if (buttonId === "btn_cancel") intent = "cancelar";
  else if (buttonId === "btn_reschedule") intent = "reagendar";

  if (!intent) {
    functions.logger.info("Botón no reconocido", {buttonId});
    return;
  }

  // Bloqueo de re-pulsación: si el paciente ya pulsó algún botón del
  // recordatorio para esta cita, ignoramos pulsaciones posteriores y
  // respondemos con un acuse claro. Evita confusión cuando el cliente
  // explora los botones tras haber tomado ya una decisión.
  if (cita) {
    try {
      const citaSnap = await db.collection("clinni_appointments").doc(cita.id).get();
      const data = citaSnap.data() ?? {};
      if (data.recordatorioBotonPulsado === true) {
        const tipoPrev = (data.recordatorioBotonPulsadoTipo as string | undefined) ?? "una opción";
        functions.logger.info("Botón ya consumido — ignorando", {
          citaId: cita.id, buttonIdActual: buttonId, tipoPrev,
        });
        await sendTextMessage(
            {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
            "Ya tenemos anotada tu respuesta a esta cita 🙂 " +
            "Si necesitas algo más, escríbenos por aquí y te atendemos.",
        );
        return;
      }
      // Marcamos la cita ANTES de procesar para minimizar race con
      // pulsaciones concurrentes. Si el process posterior falla, el flag
      // queda set; recepción puede limpiarlo manualmente desde el panel.
      await citaSnap.ref.update({
        recordatorioBotonPulsado: true,
        recordatorioBotonPulsadoEn: admin.firestore.Timestamp.now(),
        recordatorioBotonPulsadoTipo: buttonId,
      });
    } catch (e) {
      functions.logger.warn("No se pudo verificar/marcar recordatorioBotonPulsado", {
        citaId: cita.id, error: String(e),
      });
      // No bloqueamos el flujo — preferimos procesar duplicado a no procesar.
    }
  }

  const convId = conv?.id ?? await createConversation({
    pacienteNombre: cita?.pacienteNombre ?? "(sin registrar)",
    pacienteTelefono: telefono,
    appointmentId: cita?.id ?? null,
    tipo: "paciente_iniciado",
    profesional: cita?.profesional ?? "",
    fechaCita: cita?.fechaCita ?? null,
    textoInicial: `(botón pulsado: ${buttonId})`,
    rolInicial: "paciente",
  });
  if (conv) {
    await appendMessageToConversation(conv.id, "paciente", `(botón: ${buttonId})`);
  }
  // Para botones calculamos dentro48h en código (no hay IA aquí). Fuerza mayor
  // no se puede detectar desde un botón de recordatorio, así que false.
  const dentro48h = cita ?
    (cita.fechaCita.getTime() - Date.now()) / (1000 * 60 * 60) < 48 :
    false;
  await executeAction(
      intent, "es", dentro48h, false, convId, cita, telefono,
      `(botón: ${buttonId})`, config, waToken,
      cita?.pacienteNombre || telefono,
  );
}

export const whatsappWebhook = onRequest(
    {
      region: "europe-southwest1",
      secrets: [
        WHATSAPP_TOKEN,
        WHATSAPP_APP_SECRET,
        WHATSAPP_VERIFY_TOKEN,
        ANTHROPIC_API_KEY,
      ],
      memory: "512MiB",
      timeoutSeconds: 60,
      // minInstances:1 mantiene un contenedor caliente 24/7 para evitar
      // cold starts (~22s observados con todas las lecturas Firestore en
      // frío). Coste estimado: ~5-7 USD/mes. Compensado por UX: el bot
      // responde en <2s en lugar de 20-25s en mensajes "fríos".
      minInstances: 1,
      cors: false, // Webhook público, validamos firma manualmente
    },
    async (req, res) => {
      // ─── GET: verificación inicial ──────────────────────────
      if (req.method === "GET") {
        const mode = req.query["hub.mode"];
        const token = req.query["hub.verify_token"];
        const challenge = req.query["hub.challenge"];
        if (mode === "subscribe" && token === WHATSAPP_VERIFY_TOKEN.value()) {
          functions.logger.info("Webhook verificado por Meta");
          res.status(200).send(challenge);
          return;
        }
        functions.logger.warn("GET webhook con verify_token incorrecto");
        res.status(403).send("forbidden");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).send("method not allowed");
        return;
      }

      // ─── POST: validar firma HMAC ───────────────────────────
      const signature = req.header("x-hub-signature-256");
      const rawBody = (req as unknown as {rawBody?: Buffer}).rawBody;
      const rawBodyStr = rawBody ? rawBody.toString("utf8") : JSON.stringify(req.body);
      const valid = validateMetaSignature(
          WHATSAPP_APP_SECRET.value(),
          signature,
          rawBodyStr,
      );
      if (!valid) {
        functions.logger.warn("Firma inválida en webhook POST");
        res.status(401).send("invalid signature");
        return;
      }

      // ACK inmediato a Meta para evitar reintentos
      res.status(200).send("ok");

      // ─── Procesado en background ────────────────────────────
      // Capturamos el teléfono fuera del try para poder enviar fallback al
      // paciente si algo falla en mitad del procesamiento (índice faltante,
      // Claude caído, etc.). Sin esto el bot quedaría mudo y el paciente no
      // sabría que su mensaje llegó.
      let fromForFallback = "";
      try {
        const body = req.body;
        const entry = body?.entry?.[0];
        const change = entry?.changes?.[0];
        const value = change?.value;
        const messages = value?.messages;
        if (!messages || messages.length === 0) {
          // Puede ser un evento de status (delivered, read), lo ignoramos
          return;
        }

        const msg = messages[0];
        const from = String(msg.from ?? ""); // teléfono del paciente
        if (!from) return;
        fromForFallback = from;

        // ─── Idempotencia: descartar duplicados de Meta (at-least-once) ──
        const messageId = String(msg.id ?? "");
        const isFirst = await claimMessageId(messageId);
        if (!isFirst) return;

        const waToken = WHATSAPP_TOKEN.value();
        const appSecret = WHATSAPP_APP_SECRET.value();
        const anthropicKey = ANTHROPIC_API_KEY.value();
        const config = await loadConfig();

        // ─── Filtro 1: silencio absoluto al propio teléfono de recepción ─
        // Recepción usa el bot para escalado, no debería convertirse en
        // paciente del mismo bot. Si recepción reacciona con un emoji a un
        // DM nuestro, Meta nos manda un evento "reaction" que sin este
        // filtro provocaría loop (aviso de "no soportado" → reaction al
        // aviso → otro aviso → ...). Aplicamos también a otros tipos por
        // seguridad: que recepción "escriba" al bot no genere flujo bot.
        if (config.grupoRecepcionId && from === config.grupoRecepcionId) {
          functions.logger.info(
              "Mensaje del propio teléfono de recepción ignorado",
              {from, type: msg.type},
          );
          return;
        }

        // ─── Filtro 2: ignorar reactions (emojis sobre nuestros mensajes) ─
        // Las reactions son feedback al mensaje original, no son mensajes
        // nuevos. No queremos responder ni escalar.
        if (msg.type === "reaction") {
          functions.logger.info("Reaction ignorada", {
            from,
            emoji: (msg as Record<string, {emoji?: string}>).reaction?.emoji,
          });
          return;
        }

        if (msg.type === "text") {
          const texto = String(msg.text?.body ?? "").trim();
          if (!texto) return;
          await processIncomingText(from, texto, waToken, appSecret, anthropicKey);
        } else if (msg.type === "interactive" || msg.type === "button") {
          // Pulsaciones de botones. Hay dos formatos según origen:
          //  - msg.type === "interactive" → botones de sendButtonMessage
          //    (texto libre con botones). Llega .interactive.button_reply.id
          //    con el ID que pusimos al enviarlos (btn_confirm, slot_X, etc.).
          //  - msg.type === "button" → quick_reply de un TEMPLATE aprobado
          //    de Meta. Llega .button.text y .button.payload con el texto
          //    del botón ("Confirmar", "Cambiar cita", "Cancelar"). Meta
          //    NO permite IDs custom en templates, solo el text.
          //
          // Mapeamos el text/title a los IDs internos para que el resto
          // del flujo (executeAction, política 48h, slots) sea idéntico
          // sin importar el origen del botón.
          const rawId = msg.interactive?.button_reply?.id ??
            msg.interactive?.list_reply?.id;
          const rawTitle = msg.interactive?.button_reply?.title ??
            msg.interactive?.list_reply?.title ??
            (msg as Record<string, {text?: string; payload?: string}>).button?.text ??
            (msg as Record<string, {text?: string; payload?: string}>).button?.payload;
          let buttonId = rawId ? String(rawId) : "";
          if (!buttonId.startsWith("btn_") && !buttonId.startsWith("slot_")) {
            const titleLower = (rawTitle ?? "").toLowerCase().trim();
            if (titleLower === "confirmar") buttonId = "btn_confirm";
            else if (titleLower === "cambiar cita") buttonId = "btn_reschedule";
            else if (titleLower === "cancelar") buttonId = "btn_cancel";
            functions.logger.info("Botón template/interactive normalizado", {
              msgType: msg.type, rawId, rawTitle, mappedTo: buttonId,
            });
          }
          if (!buttonId) return;
          await processInteractiveReply(from, buttonId, waToken, config);
        } else if (
          msg.type === "image" || msg.type === "document" ||
          msg.type === "audio" || msg.type === "video" || msg.type === "sticker"
        ) {
          // Extraemos el media_id y filename según el tipo. La estructura
          // del payload de Meta varía: image/audio/video/sticker traen .id
          // dentro del nodo del tipo; document además trae filename original.
          const mediaNode = (msg as Record<string, {id?: string; filename?: string; caption?: string}>)[msg.type];
          const mediaId = mediaNode?.id;
          const filename = mediaNode?.filename;
          const caption = mediaNode?.caption ?? "";

          let stored: Awaited<ReturnType<typeof fetchMediaAndStore>> = null;
          if (mediaId) {
            stored = await fetchMediaAndStore(mediaId, waToken, from, filename);
          }

          await sendTextMessage(
              {phoneId: config.whatsappPhoneId, token: waToken, to: from},
              "Recibido el archivo 👍 Recepción lo revisa y te dice algo enseguida.",
          );

          // Notificar a recepción con link al archivo si lo hemos almacenado.
          const extra: string[] = [];
          if (stored) {
            extra.push(`📎 Archivo: ${stored.signedUrl}`);
            extra.push(`   Tipo: ${stored.mimeType} (${Math.round(stored.sizeBytes / 1024)} KB)`);
            extra.push(`   Storage: ${stored.storagePath}`);
          } else {
            extra.push("⚠️ No se pudo descargar el archivo de Meta — atender manualmente");
          }
          if (caption) extra.push(`💬 Texto adjunto: "${caption}"`);
          await notifyRecepcion(config, waToken, buildRecepcionMsg({
            icono: "📎",
            titulo: `ADJUNTO ${msg.type.toUpperCase()}`,
            telefono: from,
            extra,
            cta: "Posible justificante (parte médico, baja). Revisar el archivo y actuar.",
          }));
        } else {
          // Tipos sin media_id (location, contacts, reaction, etc.)
          await sendTextMessage(
              {phoneId: config.whatsappPhoneId, token: waToken, to: from},
              "Por aquí no puedo abrir ese tipo de mensaje, pero recepción te contacta enseguida 🙂",
          );
          await notifyRecepcion(config, waToken, buildRecepcionMsg({
            icono: "📎",
            titulo: `MENSAJE NO SOPORTADO (${msg.type})`,
            telefono: from,
            cta: "Tipo de mensaje no procesable por el bot (location/reaction/etc.). Atender manualmente.",
          }));
        }
      } catch (e) {
        functions.logger.error("Webhook background processing error", e);
        // Fallback: si hemos identificado el paciente, intentamos al menos
        // enviarle un mensaje básico para que no quede sin respuesta. Si esto
        // también falla (token caducado, Meta caído), no hay nada más que hacer.
        if (fromForFallback) {
          try {
            const config = await loadConfig().catch(() => DEFAULT_CONFIG);
            await sendTextMessage(
                {
                  phoneId: config.whatsappPhoneId,
                  token: WHATSAPP_TOKEN.value(),
                  to: fromForFallback,
                },
                "¡Hola! 👋 Recibido tu mensaje. Recepción te atiende enseguida.",
            );
          } catch (fallbackErr) {
            functions.logger.error("Webhook fallback send también falló", fallbackErr);
          }
        }
      }
    },
);
