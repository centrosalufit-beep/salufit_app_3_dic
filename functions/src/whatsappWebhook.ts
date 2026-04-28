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
import {sendTextMessage, validateMetaSignature} from "./whatsapp";
import {classifyIntent, BotIntent} from "./claude";

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
  await sendTextMessage(
      {phoneId: config.whatsappPhoneId, token, to: config.grupoRecepcionId},
      mensaje,
  );
}

/**
 * Idempotencia: Meta entrega webhooks at-least-once y reintenta hasta 36h.
 * Cada mensaje trae un id único; lo guardamos con TTL para no procesar
 * dos veces. Devuelve true si es el primer procesamiento, false si ya
 * estaba registrado (= duplicado a ignorar).
 */
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
  const config = await loadConfig();
  if (!config.activo) {
    functions.logger.info("Bot inactivo, mensaje ignorado", {telefono});
    return;
  }

  const cita = await findUpcomingAppointment(telefono);
  let conv = await findActiveConversation(telefono);

  // Si el usuario inicia conversación sin cita asociada, intentar reagendar/escalar igualmente
  if (!conv) {
    const convId = await createConversation({
      pacienteNombre: cita?.pacienteNombre ?? "(sin registrar)",
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
  const horasHastaCita = cita ?
    (cita.fechaCita.getTime() - Date.now()) / (1000 * 60 * 60) :
    Number.POSITIVE_INFINITY;

  const classification = await classifyIntent(anthropicKey, texto, {
    pacienteNombre: cita?.pacienteNombre ?? "",
    fechaCita: cita ? cita.fechaCita.toISOString() : "",
    profesional: cita?.profesional ?? "",
    servicio: cita?.servicio ?? "",
    isWithinBusinessHours: inHours,
    horasHastaCita,
  });

  if (!classification) {
    // Fallback genérico si la IA falla
    await sendTextMessage(
        {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
        "Gracias por tu mensaje. Te contactaremos desde recepción en breve.",
    );
    await appendMessageToConversation(
        conv.id,
        "bot",
        "(fallback IA) Gracias por tu mensaje. Te contactaremos desde recepción.",
        {estado: "escalada", intencionDetectada: "escalate"},
    );
    await notifyRecepcion(
        config,
        waToken,
        `⚠️ Bot fallback: ${cita?.pacienteNombre ?? telefono}\n` +
        `Tel: ${telefono}\n` +
        `Mensaje: "${texto}"\n` +
        "(IA no disponible, atender manualmente)",
    );
    return;
  }

  // Enviar respuesta breve al paciente
  await sendTextMessage(
      {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
      classification.respuesta,
  );
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

    case "reagendar":
      // FASE 2: implementar búsqueda de huecos + botones interactivos.
      // En Fase 1 acusamos recibo y delegamos en recepción con tel directo.
      await appendMessageToConversation(convId, "bot", "(reagendación delegada a recepción)", {
        estado: "reagendar_solicitada",
        resultado: "reagendar_delegado_recepcion",
      });
      await notifyRecepcion(
          config,
          waToken,
          `🔄 REAGENDACIÓN — ${cita?.pacienteNombre ?? telefono}\n` +
          `${cita ? `Cita actual: ${formatFechaES(cita.fechaCita, "es")} con ${cita.profesional}` : "(sin cita registrada)"}\n` +
          `Tel: ${telefono}\nMensaje: "${mensajeOriginal}"\n` +
          "(Búsqueda automática de huecos pendiente fase 2)",
      );
      return;

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
          `📨 ESCALADO — ${cita?.pacienteNombre ?? telefono}\n` +
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
  // FASE 2: el botón ID lleva info del slot seleccionado, ej: "slot_2026-05-02_10:00_DraValles"
  // Por ahora solo gestionamos la respuesta del recordatorio: ["confirm", "reschedule", "cancel"]
  const conv = await findActiveConversation(telefono);
  const cita = await findUpcomingAppointment(telefono);

  let intent: BotIntent | null = null;
  if (buttonId === "btn_confirm") intent = "confirmar";
  else if (buttonId === "btn_cancel") intent = "cancelar";
  else if (buttonId === "btn_reschedule") intent = "reagendar";

  if (!intent) {
    functions.logger.info("Botón no reconocido (probablemente slot fase 2)", {buttonId});
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
        } else {
          // Tipos no soportados (image, audio, video, document, location)
          // Avisamos y escalamos
          await sendTextMessage(
              {phoneId: config.whatsappPhoneId, token: waToken, to: from},
              "Por ahora solo puedo procesar mensajes de texto. Te contactaremos desde recepción.",
          );
          await notifyRecepcion(
              config,
              waToken,
              `📎 Mensaje multimedia recibido de ${from} (tipo: ${msg.type}). Atender manualmente.`,
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
