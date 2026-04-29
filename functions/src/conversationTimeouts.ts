/**
 * Cloud Function `checkConversationTimeouts` (onSchedule).
 *
 * Cron cada 15 min. Gestiona conversaciones con botones interactivos cuando
 * el paciente no responde dentro del timeout configurado (espec sec 5.3):
 *
 *   estado="esperando_respuesta_boton"     →  pasados N min  →  recordatorio
 *                                                              + estado→_boton_2
 *   estado="esperando_respuesta_boton_2"   →  pasados N min  →  escalar a recepción
 *                                                              + estado=escalada
 *
 * Los minutos de espera vienen de config/whatsapp_bot:
 *   - minutosTimeoutPrimero (default 30)
 *   - minutosTimeoutSegundo (default 30)
 *
 * Region europe-west1 — Cloud Scheduler no soporta europe-southwest1.
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import {defineSecret} from "firebase-functions/params";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {sendTextMessage, sendButtonMessage} from "./whatsapp";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

const WHATSAPP_TOKEN = defineSecret("WHATSAPP_TOKEN");

interface BotConfigTimeouts {
  whatsappPhoneId: string;
  grupoRecepcionId: string;
  minutosTimeoutPrimero: number;
  minutosTimeoutSegundo: number;
  activo: boolean;
}

async function loadConfig(): Promise<BotConfigTimeouts> {
  const fallback: BotConfigTimeouts = {
    whatsappPhoneId: "723362620868862",
    grupoRecepcionId: "",
    minutosTimeoutPrimero: 30,
    minutosTimeoutSegundo: 30,
    activo: true,
  };
  try {
    const doc = await db.collection("config").doc("whatsapp_bot").get();
    if (!doc.exists) return fallback;
    const data = doc.data() ?? {};
    return {
      whatsappPhoneId: (data.whatsappPhoneId as string) || fallback.whatsappPhoneId,
      grupoRecepcionId: (data.grupoRecepcionId as string) || "",
      minutosTimeoutPrimero:
        (data.minutosTimeoutPrimero as number) ?? fallback.minutosTimeoutPrimero,
      minutosTimeoutSegundo:
        (data.minutosTimeoutSegundo as number) ?? fallback.minutosTimeoutSegundo,
      activo: data.activo !== false,
    };
  } catch (e) {
    functions.logger.warn("loadConfig (timeouts) failed", e);
    return fallback;
  }
}

export const checkConversationTimeouts = onSchedule(
    {
      schedule: "every 15 minutes",
      region: "europe-west1",
      timeZone: "Europe/Madrid",
      secrets: [WHATSAPP_TOKEN],
      memory: "256MiB",
      timeoutSeconds: 300,
    },
    async () => {
      const config = await loadConfig();
      if (!config.activo) {
        functions.logger.info("Bot inactivo, timeouts no procesados");
        return;
      }

      const waToken = WHATSAPP_TOKEN.value();
      const now = Date.now();
      const cutoff1 = new Date(now - config.minutosTimeoutPrimero * 60 * 1000);
      const cutoff2 = new Date(now - config.minutosTimeoutSegundo * 60 * 1000);

      // 1) Conversaciones esperando_respuesta_boton con timeout pasado.
      // Disparamos recordatorio y movemos a esperando_respuesta_boton_2.
      const snapPrimer = await db
          .collection("whatsapp_conversations")
          .where("estado", "==", "esperando_respuesta_boton")
          .where(
              "fechaUltimaInteraccion",
              "<=",
              admin.firestore.Timestamp.fromDate(cutoff1),
          )
          .limit(50)
          .get();

      let recordatoriosEnviados = 0;
      for (const conv of snapPrimer.docs) {
        const data = conv.data();
        const telefono = (data.pacienteTelefono as string) ?? "";
        const nombre = (data.pacienteNombre as string) ?? "";
        if (!telefono) continue;

        const body =
          `Hola${nombre ? " " + nombre : ""}, te volvemos a contactar — ` +
          "no recibimos tu respuesta sobre la cita. ¿Podrías indicarnos qué prefieres?";
        const r = await sendButtonMessage(
            {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
            body,
            [
              {id: "btn_confirm", title: "Confirmar"},
              {id: "btn_reschedule", title: "Cambiar cita"},
              {id: "btn_cancel", title: "Cancelar"},
            ],
        );
        await conv.ref.update({
          estado: "esperando_respuesta_boton_2",
          fechaUltimaInteraccion: admin.firestore.Timestamp.now(),
          mensajes: admin.firestore.FieldValue.arrayUnion({
            rol: "bot",
            texto: body,
            timestamp: admin.firestore.Timestamp.now(),
            tipo: "recordatorio_timeout_1",
          }),
        });
        if (r.success) recordatoriosEnviados++;
        functions.logger.info("Timeout 1: recordatorio enviado", {
          convId: conv.id,
          telefono,
          success: r.success,
          messageId: r.messageId,
        });
      }

      // 2) Conversaciones esperando_respuesta_boton_2 con timeout pasado.
      // Escalamos a recepción y cerramos como timeout.
      const snapSegundo = await db
          .collection("whatsapp_conversations")
          .where("estado", "==", "esperando_respuesta_boton_2")
          .where(
              "fechaUltimaInteraccion",
              "<=",
              admin.firestore.Timestamp.fromDate(cutoff2),
          )
          .limit(50)
          .get();

      let escalados = 0;
      for (const conv of snapSegundo.docs) {
        const data = conv.data();
        const telefono = (data.pacienteTelefono as string) ?? "";
        const nombre = (data.pacienteNombre as string) ?? "(sin nombre)";

        // Notificar a recepción.
        if (config.grupoRecepcionId) {
          const aviso =
            `⏰ TIMEOUT — ${nombre}\n` +
            `Tel: ${telefono}\n` +
            "El paciente no respondió a 2 recordatorios sobre su cita. " +
            "Atender manualmente.";
          const r = await sendTextMessage(
              {phoneId: config.whatsappPhoneId, token: waToken, to: config.grupoRecepcionId},
              aviso,
          );
          functions.logger.info("Timeout 2: escalado a recepción", {
            convId: conv.id,
            telefono,
            success: r.success,
            messageId: r.messageId,
          });
        } else {
          functions.logger.warn(
              "Timeout 2 sin grupoRecepcionId configurado, escalada solo en BBDD",
              {convId: conv.id, telefono},
          );
        }

        await conv.ref.update({
          estado: "escalada",
          resultado: "timeout_sin_respuesta",
          fechaUltimaInteraccion: admin.firestore.Timestamp.now(),
        });
        escalados++;
      }

      functions.logger.info("checkConversationTimeouts ejecutado", {
        recordatoriosEnviados,
        escalados,
        cutoff1Min: config.minutosTimeoutPrimero,
        cutoff2Min: config.minutosTimeoutSegundo,
      });
    },
);
