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
import {findNextAvailableSlots, shortLabelForSlot, longLabelForSlot} from "./slots";

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
        "Hemos registrado tu solicitud de baja. No te volveremos a contactar " +
        "automáticamente desde este número. Si quieres reactivar las " +
        "comunicaciones, contacta con recepción. Gracias.\n\n— SALUFIT",
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
      "Hola, este es el WhatsApp del Centro Salufit. " +
      "No te encontramos como paciente registrado en nuestra base de datos. " +
      "Si quieres pedir información, concertar una cita o resolver una duda, " +
      `contacta con recepción al ${telRecepcion} y te atenderemos personalmente. ` +
      "Gracias.\n\n— SALUFIT";
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
    await notifyRecepcion(
        config,
        waToken,
        `🔕 Bot filtró mensaje de número no registrado.\n` +
        `Tel: ${telefono}\n` +
        `Mensaje: "${texto.slice(0, 200)}"\n` +
        "(Se le ha enviado el teléfono de recepción.)",
    );
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
        "Hola 👋 Hemos recibido tu mensaje fuera de nuestro horario de " +
        "atención (L–V 9:00–20:00). Te leemos y recepción te contactará " +
        "en cuanto abramos. Gracias por escribir a SALUFIT.";
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
    await notifyRecepcion(
        config,
        waToken,
        `⚠️ Bot fallback: ${patient?.nombreCompleto || cita?.pacienteNombre || telefono}\n` +
        `Tel: ${telefono}\n` +
        `Mensaje: "${texto}"\n` +
        (fallbackResult.success ?
          "(IA no disponible, atender manualmente)" :
          `(IA no disponible Y envío fallback FALLÓ: ${fallbackResult.error ?? "?"})`),
    );
    return;
  }

  // Enviar respuesta breve al paciente
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
  await appendMessageToConversation(conv.id, "bot", classification.respuesta, {
    intencionDetectada: classification.intencion,
    idiomaDetectado: classification.idiomaDetectado,
    dentro48h: classification.dentro48h,
    fuerzaMayor: classification.fuerzaMayor,
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
        await notifyRecepcion(
            config,
            waToken,
            `❓ Paciente confirma sin cita registrada:\n` +
            `Tel: ${telefono}\nMensaje: "${mensajeOriginal}"`,
        );
      }
      return;

    case "cancelar":
      if (cita && dentro48h) {
        // POLÍTICA 48h: NO cancelamos automáticamente. Escalamos a Alba para
        // que decida. El bot ya envió la respuesta explicando la política antes
        // de llegar aquí. Si la IA detectó fuerza mayor, lo destacamos en el
        // aviso para que Alba lo valore con prioridad.
        const resultado = fuerzaMayor ?
          "cancelar_dentro_48h_fuerza_mayor" :
          "cancelar_dentro_48h_escalado";
        await appendMessageToConversation(convId, "bot",
            "(cancelación dentro de 48h, decisión recepción)", {
              estado: "cancelacion_solicitada",
              resultado,
            });
        const cabecera = fuerzaMayor ?
          "🆘 [ALBA] CANCELACIÓN <48h CON FUERZA MAYOR ALEGADA" :
          "⚠️ [ALBA] CANCELACIÓN DENTRO DE 48h";
        const politica = fuerzaMayor ?
          "(Política: paciente alega fuerza mayor — valorar exención. " +
          "Si no procede, ofrecer reagendar +48h o 55€ Bizum.)" :
          "(Política: reagendar dentro de 48h — máx 2 veces — o 55€ Bizum. " +
          "Decisión humana.)";
        await notifyRecepcion(
            config,
            waToken,
            `${cabecera} — ${cita.pacienteNombre}\n` +
            `Cita: ${formatFechaES(cita.fechaCita, "es")}\n` +
            `Profesional: ${cita.profesional}\n` +
            `Tel: ${telefono}\n` +
            `Mensaje: "${mensajeOriginal}"\n` +
            politica,
        );
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
        await notifyRecepcion(
            config,
            waToken,
            `🚫 CANCELACIÓN — ${cita.pacienteNombre}\n` +
            `Cita: ${formatFechaES(cita.fechaCita, "es")}\n` +
            `Profesional: ${cita.profesional}\n` +
            `Tel: ${telefono}`,
        );
      } else {
        await notifyRecepcion(
            config,
            waToken,
            `❓ Cancelación sin cita registrada:\nTel: ${telefono}\nMensaje: "${mensajeOriginal}"`,
        );
      }
      return;

    case "reagendar": {
      // FASE 2: búsqueda automática de huecos del MISMO profesional + botones.
      //
      // Si no hay cita asociada, no hay profesional desde el que buscar →
      // escalamos. Si el profesional tiene escalaDirectaParaReagendar=true
      // (odontología, Estela, Andressa) o no está activo → escalamos.
      // Si encuentra ≥1 slot libre, ofrecemos como botones interactivos.

      if (!cita) {
        await appendMessageToConversation(convId, "bot",
            "(reagendación sin cita registrada — delegada a recepción)", {
              estado: "reagendar_solicitada",
              resultado: "reagendar_sin_cita",
            });
        await notifyRecepcion(config, waToken,
            `🔄 REAGENDACIÓN sin cita registrada — ${pacienteNombre}\n` +
            `Tel: ${telefono}\nMensaje: "${mensajeOriginal}"`);
        return;
      }

      // Si dentro48h: la nueva cita debe estar dentro de 48h siguientes.
      const restrictToBeforeMs = dentro48h ?
        cita.fechaCita.getTime() + 48 * 60 * 60 * 1000 :
        undefined;

      const {schedule, slots} = await findNextAvailableSlots(cita.profesional, {
        count: 2,
        bufferMinutosDesdeAhora: 60,
        diasVista: 14,
        restrictToBeforeMs,
      });

      // Profesional no encontrado, inactivo o configurado para escalar siempre.
      if (!schedule || !schedule.activo || schedule.escalaDirectaParaReagendar) {
        const motivo = !schedule ? "no encontrado en professional_schedules" :
          !schedule.activo ? "inactivo" :
            schedule.motivoEscalaDirecta ?? "escalada directa configurada";
        await appendMessageToConversation(convId, "bot",
            `(reagendación → escalada: profesional ${motivo})`, {
              estado: "reagendar_solicitada",
              resultado: "reagendar_escalado_recepcion",
            });
        await notifyRecepcion(config, waToken,
            `🔄 REAGENDACIÓN — ${pacienteNombre}\n` +
            `Cita actual: ${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}\n` +
            `Tel: ${telefono}\nMensaje: "${mensajeOriginal}"\n` +
            `(Profesional ${motivo}; recepción gestiona manualmente.)`);
        return;
      }

      // Sin huecos en la ventana → escalar.
      if (slots.length === 0) {
        await appendMessageToConversation(convId, "bot",
            "(reagendación → sin huecos disponibles, escalada)", {
              estado: "reagendar_solicitada",
              resultado: "reagendar_sin_huecos",
            });
        await notifyRecepcion(config, waToken,
            `🔄 REAGENDACIÓN sin huecos automáticos — ${pacienteNombre}\n` +
            `Cita actual: ${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}\n` +
            `Tel: ${telefono}\n` +
            (dentro48h ? "(dentro de 48h: ventana limitada a +48h)" : "(ventana 14 días vista vacía)"));
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
      const body =
        `Tenemos estos huecos con ${schedule.nombre}:\n\n${detalleTextos}\n\n` +
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
      await notifyRecepcion(
          config,
          waToken,
          `📨 ESCALADO — ${pacienteNombre}\n` +
          `Tel: ${telefono}\nMensaje: "${mensajeOriginal}"\n` +
          "(Bot derivó a humano)",
      );
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
          "Entendido. Recepción te contactará para buscarte otro horario que te encaje. Gracias.\n\n— SALUFIT",
      );
      await notifyRecepcion(config, waToken,
          `🔄 REAGENDACIÓN — paciente pidió "Otro horario"\n` +
          `Tel: ${telefono}\n` +
          (cita ? `Cita actual: ${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}\n` : "") +
          "(Buscar hueco manualmente y confirmar.)");
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
      await notifyRecepcion(config, waToken,
          `⚠️ Botón slot fuera de rango: ${buttonId} (${idx}/${slots.length}) tel ${telefono}`);
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
    await sendTextMessage(
        {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
        `Anotado: te reagendamos para el ${fechaTexto} con ${slot.profesionalNombre}. ` +
        "Recepción confirmará el cambio en breve. Gracias.\n\n— SALUFIT",
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
    await notifyRecepcion(config, waToken,
        `✅ REAGENDACIÓN solicitada por paciente — confirmar en Clinni\n` +
        `Tel: ${telefono}\n` +
        (cita ? `Cita anterior: ${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}\n` : "") +
        `Cita nueva: ${fechaTexto} con ${slot.profesionalNombre}\n` +
        "(Actualizar Clinni y avisar al paciente si hay incidencia.)");
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

        if (msg.type === "text") {
          const texto = String(msg.text?.body ?? "").trim();
          if (!texto) return;
          await processIncomingText(from, texto, waToken, appSecret, anthropicKey);
        } else if (msg.type === "interactive") {
          const buttonId = msg.interactive?.button_reply?.id ?? msg.interactive?.list_reply?.id;
          if (!buttonId) return;
          await processInteractiveReply(from, String(buttonId), waToken, config);
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
              "Hemos recibido tu archivo. Recepción lo revisará y te contactará en breve. " +
              "Gracias.\n\n— SALUFIT",
          );

          // Notificar a recepción con link al archivo si lo hemos almacenado.
          const link = stored ?
            `Archivo: ${stored.signedUrl}\n` +
            `Tipo: ${stored.mimeType} (${Math.round(stored.sizeBytes / 1024)} KB)\n` +
            `Storage: ${stored.storagePath}\n` :
            "(no se pudo descargar el archivo de Meta — atender manualmente)\n";
          await notifyRecepcion(
              config,
              waToken,
              `📎 ADJUNTO ${msg.type.toUpperCase()} de ${from}\n` +
              link +
              (caption ? `Texto adjunto: "${caption}"\n` : "") +
              "Posible justificante (parte médico, baja, etc.).",
          );
        } else {
          // Tipos sin media_id (location, contacts, reaction, etc.)
          await sendTextMessage(
              {phoneId: config.whatsappPhoneId, token: waToken, to: from},
              "Por ahora no puedo procesar ese tipo de mensaje. Te contactaremos desde recepción.",
          );
          await notifyRecepcion(
              config,
              waToken,
              `📎 Mensaje recibido de ${from} (tipo: ${msg.type}). Atender manualmente.`,
          );
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
                "Gracias por contactar con SALUFIT. Hemos recibido tu mensaje y " +
                "una persona de recepción te atenderá en breve.",
            );
          } catch (fallbackErr) {
            functions.logger.error("Webhook fallback send también falló", fallbackErr);
          }
        }
      }
    },
);
