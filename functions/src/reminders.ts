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
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import {defineSecret} from "firebase-functions/params";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {sendButtonMessage} from "./whatsapp";

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
      const config = await loadConfig();
      if (!config.activo) {
        functions.logger.info("Bot inactivo, recordatorios no enviados");
        return;
      }

      const now = new Date();
      const desde = new Date(
          now.getTime() + (config.horasAntelacionRecordatorio - 4) * 60 * 60 * 1000,
      );
      const hasta = new Date(
          now.getTime() + (config.horasAntelacionRecordatorio + 24) * 60 * 60 * 1000,
      );

      const snap = await db
          .collection("clinni_appointments")
          .where("recordatorioEnviado", "==", false)
          .where("estado", "==", "pendiente")
          .where("fechaCita", ">=", admin.firestore.Timestamp.fromDate(desde))
          .where("fechaCita", "<=", admin.firestore.Timestamp.fromDate(hasta))
          .limit(50)
          .get();

      if (snap.empty) {
        functions.logger.info("Sin citas pendientes de recordatorio");
        return;
      }

      const waToken = WHATSAPP_TOKEN.value();
      let sent = 0;
      let failed = 0;

      for (const doc of snap.docs) {
        const data = doc.data();
        const telefono = (data.pacienteTelefono as string) ?? "";
        const nombre = (data.pacienteNombre as string) ?? "";
        const profesional = (data.profesional as string) ?? "";
        const servicio = (data.servicio as string) ?? "";
        const fechaCita = (data.fechaCita as admin.firestore.Timestamp).toDate();
        if (!telefono) continue;

        const fechaFmt = formatFecha(fechaCita);
        const body =
        `Hola ${nombre}, te recordamos tu cita en Centro Salufit:\n\n` +
        `📅 ${fechaFmt}\n` +
        `👤 Profesional: ${profesional}\n` +
        (servicio ? `💼 Servicio: ${servicio}\n\n` : "\n") +
        "Por favor, confirma tu asistencia:";

        const result = await sendButtonMessage(
            {phoneId: config.whatsappPhoneId, token: waToken, to: telefono},
            body,
            [
              {id: "btn_confirm", title: "Confirmar"},
              {id: "btn_reschedule", title: "Cambiar cita"},
              {id: "btn_cancel", title: "Cancelar"},
            ],
        );

        if (result.success) {
          sent++;
          await doc.ref.update({
            recordatorioEnviado: true,
            fechaRecordatorio: admin.firestore.FieldValue.serverTimestamp(),
          });
          // Crear conversación de tipo recordatorio
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

      functions.logger.info("Recordatorios procesados", {sent, failed, total: snap.size});
    },
);
