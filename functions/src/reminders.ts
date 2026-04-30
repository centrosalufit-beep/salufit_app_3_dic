/**
 * Cloud Function `sendAppointmentReminders` (onSchedule).
 *
 * Cron cada 30 minutos. Busca citas en `clinni_appointments` cuya
 * fechaCita esté entre ahora+20h y ahora+48h, estado="pendiente" y
 * recordatorioEnviado=false. Para cada una envía un mensaje de
 * recordatorio por WhatsApp con 3 botones interactivos:
 *   - btn_confirm  → Confirmar
 *   - btn_reschedule → Cambiar cita (Fase 2)
 *   - btn_cancel   → Cancelar
 *
 * Tras enviar, marca recordatorioEnviado=true y crea conversación
 * en `whatsapp_conversations`.
 *
 * También expone `triggerRemindersNow` (callable HTTPS) para disparar
 * la misma lógica manualmente desde un script de admin (útil para test).
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {sendButtonMessage, sendTemplateMessage} from "./whatsapp";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

const WHATSAPP_TOKEN = defineSecret("WHATSAPP_TOKEN");

interface BotConfig {
  whatsappPhoneId: string;
  horasAntelacionRecordatorio: number;
  activo: boolean;
}

async function loadConfig(): Promise<BotConfig> {
  try {
    const doc = await db.collection("config").doc("whatsapp_bot").get();
    if (!doc.exists) {
      return {
        whatsappPhoneId: "723362620868862",
        horasAntelacionRecordatorio: 24,
        activo: true,
      };
    }
    const data = doc.data() ?? {};
    return {
      whatsappPhoneId: (data.whatsappPhoneId as string) || "723362620868862",
      horasAntelacionRecordatorio:
        (data.horasAntelacionRecordatorio as number) ?? 24,
      activo: data.activo !== false,
    };
  } catch (e) {
    functions.logger.warn("loadConfig failed", e);
    return {
      whatsappPhoneId: "723362620868862",
      horasAntelacionRecordatorio: 24,
      activo: true,
    };
  }
}

function formatFecha(date: Date): string {
  return date.toLocaleString("es-ES", {
    timeZone: "Europe/Madrid",
    weekday: "long",
    day: "numeric",
    month: "long",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/**
 * Lógica reusable del recordatorio. Se invoca tanto desde el cron como
 * desde el callable manual. Si `forceWindow` se pasa, la búsqueda usa
 * esa ventana en lugar de la calculada con horasAntelacionRecordatorio
 * (útil para test: pasar una ventana amplia y forzar envío inmediato).
 */
async function runReminders(opts?: {
  forceWindowHoursStart?: number;
  forceWindowHoursEnd?: number;
  forceAppointmentId?: string;
  waTokenOverride?: string;
}): Promise<{sent: number; failed: number; scanned: number}> {
  const config = await loadConfig();
  if (!config.activo) {
    functions.logger.info("Bot inactivo, recordatorios no enviados");
    return {sent: 0, failed: 0, scanned: 0};
  }

  const waToken = opts?.waTokenOverride ?? WHATSAPP_TOKEN.value();
  const now = new Date();

  let docsSnap: FirebaseFirestore.QuerySnapshot;
  if (opts?.forceAppointmentId) {
    // Modo test: forzar UNA cita específica por ID, ignora ventana y flags.
    const single = await db.collection("clinni_appointments")
        .doc(opts.forceAppointmentId).get();
    if (!single.exists) {
      functions.logger.warn("forceAppointmentId no existe", {
        id: opts.forceAppointmentId,
      });
      return {sent: 0, failed: 0, scanned: 0};
    }
    docsSnap = {
      docs: [single],
      empty: false,
      size: 1,
    } as unknown as FirebaseFirestore.QuerySnapshot;
  } else {
    const horasIni = opts?.forceWindowHoursStart ??
      (config.horasAntelacionRecordatorio - 4);
    const horasFin = opts?.forceWindowHoursEnd ??
      (config.horasAntelacionRecordatorio + 24);
    const desde = new Date(now.getTime() + horasIni * 60 * 60 * 1000);
    const hasta = new Date(now.getTime() + horasFin * 60 * 60 * 1000);

    docsSnap = await db
        .collection("clinni_appointments")
        .where("recordatorioEnviado", "==", false)
        .where("estado", "==", "pendiente")
        .where("fechaCita", ">=", admin.firestore.Timestamp.fromDate(desde))
        .where("fechaCita", "<=", admin.firestore.Timestamp.fromDate(hasta))
        .limit(50)
        .get();
  }

  if (docsSnap.empty) {
    functions.logger.info("Sin citas pendientes de recordatorio");
    return {sent: 0, failed: 0, scanned: 0};
  }

  let sent = 0;
  let failed = 0;

  for (const doc of docsSnap.docs) {
    const data = doc.data();
    const telefono = (data.pacienteTelefono as string) ?? "";
    const nombre = (data.pacienteNombre as string) ?? "";
    const profesional = (data.profesional as string) ?? "";
    const servicio = (data.servicio as string) ?? "";
    const fechaCita = (data.fechaCita as admin.firestore.Timestamp).toDate();
    if (!telefono) continue;

    const fechaFmt = formatFecha(fechaCita);
    // No mencionamos al profesional concreto al cliente (decisión opción B
    // 2026-04-30): si recepción reasigna por agenda, el cliente no debe
    // tener expectativa fijada con un nombre. Mostramos solo el servicio.
    void profesional;
    const body =
      `Hola ${nombre}, te recordamos tu cita en Centro Salufit:\n\n` +
      `📅 ${fechaFmt}\n` +
      `💼 ${servicio || "Cita"}\n\n` +
      "Por favor, confirma tu asistencia:";

    // ENVÍO PRINCIPAL: template aprobado por Meta. Pasa la regla de la
    // ventana 24h (puede iniciarse conversación sin que el paciente haya
    // escrito antes). Las {{1}}, {{2}}, {{3}} se mapean en orden:
    //   {{1}} = nombre paciente
    //   {{2}} = fecha formateada
    //   {{3}} = servicio (o "Cita" si vacío)
    // Quick-reply buttons del template ("Confirmar", "Cambiar cita",
    // "Cancelar") los maneja processInteractiveReply detectando por title.
    let result = await sendTemplateMessage(
        {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
        "recordatorio_cita_v2",
        "es",
        [nombre || "paciente", fechaFmt, servicio || "Cita"],
    );

    // FALLBACK: si la API rechaza el template (no aprobado, error, etc.)
    // intentamos texto libre con botones interactivos. SOLO funcionará si
    // el paciente ya tiene una ventana 24h abierta con el bot.
    if (!result.success) {
      functions.logger.warn(
          "Template recordatorio_cita_v2 falló, intentando texto libre",
          {error: result.error, telefono},
      );
      result = await sendButtonMessage(
          {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
          body,
          [
            {id: "btn_confirm", title: "Confirmar"},
            {id: "btn_reschedule", title: "Cambiar cita"},
            {id: "btn_cancel", title: "Cancelar"},
          ],
      );
    }

    if (result.success) {
      sent++;
      await doc.ref.update({
        recordatorioEnviado: true,
        fechaRecordatorio: admin.firestore.FieldValue.serverTimestamp(),
      });
      await db.collection("whatsapp_conversations").add({
        pacienteNombre: nombre,
        pacienteTelefono: telefono,
        appointmentId: doc.id,
        tipo: "recordatorio",
        estado: "activa",
        intencionDetectada: null,
        resultado: null,
        mensajes: [
          {
            rol: "bot",
            texto: body,
            timestamp: admin.firestore.Timestamp.now(),
          },
        ],
        fechaCreacion: admin.firestore.FieldValue.serverTimestamp(),
        fechaUltimaInteraccion: admin.firestore.FieldValue.serverTimestamp(),
        gestionadoPor: "bot",
        profesional,
        fechaCita: data.fechaCita,
      });
    } else {
      failed++;
      functions.logger.warn("Recordatorio falló", {
        telefono,
        appointmentId: doc.id,
        error: result.error,
      });
    }
  }

  functions.logger.info("Recordatorios procesados", {
    sent, failed, total: docsSnap.size,
  });
  return {sent, failed, scanned: docsSnap.size};
}

export const sendAppointmentReminders = onSchedule(
    {
      schedule: "every 30 minutes",
      // Region europe-west1 (Bélgica) porque Cloud Scheduler no soporta
      // europe-southwest1. Firestore en mismo proyecto, latencia ~15ms.
      region: "europe-west1",
      timeZone: "Europe/Madrid",
      secrets: [WHATSAPP_TOKEN],
      memory: "256MiB",
      timeoutSeconds: 540,
    },
    async () => {
      await runReminders();
    },
);

/**
 * Callable HTTPS para disparar recordatorios manualmente. Usado en tests
 * y por el panel admin si se quiere forzar el envío sin esperar al cron.
 *
 * Solo admins (rol "admin" o "administrador" en users_app/{uid}). Acepta
 * opcionalmente forceAppointmentId para procesar una sola cita.
 */
export const triggerRemindersNow = onCall(
    {
      region: "europe-west1",
      secrets: [WHATSAPP_TOKEN],
      memory: "256MiB",
      timeoutSeconds: 300,
    },
    async (req) => {
      if (!req.auth) {
        throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
      }
      // Verificar rol admin.
      const userDoc = await db.collection("users_app").doc(req.auth.uid).get();
      const rol = ((userDoc.data()?.rol as string) ?? "").toLowerCase();
      if (!["admin", "administrador"].includes(rol)) {
        throw new HttpsError("permission-denied", "Solo admins pueden disparar recordatorios.");
      }

      const data = (req.data ?? {}) as {
        forceAppointmentId?: string;
        forceWindowHoursStart?: number;
        forceWindowHoursEnd?: number;
      };

      const result = await runReminders({
        forceAppointmentId: data.forceAppointmentId,
        forceWindowHoursStart: data.forceWindowHoursStart,
        forceWindowHoursEnd: data.forceWindowHoursEnd,
      });
      return {success: true, ...result};
    },
);
