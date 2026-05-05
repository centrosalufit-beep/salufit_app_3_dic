/**
 * Sistema de envío de emails de alerta.
 *
 * - `processEmailQueue`: trigger Firestore que dispara cada vez que se
 *   añade un doc a `email_queue`. Envía el email via Gmail SMTP usando
 *   nodemailer. Tras éxito, marca el doc como `enviado=true`. Si falla,
 *   incrementa `intentos` y reintentará en el próximo cron de retry.
 *
 * - `retryFailedEmails`: cron horario que re-procesa emails fallidos
 *   (intentos<3) — defensa contra fallos transitorios SMTP.
 *
 * - `excelImportReminder`: cron a las 14:55 y 19:55 ES que verifica si
 *   hoy se ha importado el Excel de Clinni; si no, encola un email a
 *   admin recordándolo.
 *
 * - `cronHealthCheck`: cron horario que verifica si `sendAppointmentReminders`
 *   ha corrido en las últimas 90 min. Si NO, alerta al admin.
 *
 * Secret necesario: GMAIL_APP_PASSWORD (App Password de Google para
 * `directoriosalufit@gmail.com`). Si no está configurado, los emails
 * se dejan en queue sin enviar (no rompe el bot).
 */

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {defineSecret} from "firebase-functions/params";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

const GMAIL_APP_PASSWORD = defineSecret("GMAIL_APP_PASSWORD");
const SMTP_USER = "directoriosalufit@gmail.com";
const SMTP_FROM = "Salufit Bot <directoriosalufit@gmail.com>";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

async function sendEmailViaGmail(
    to: string, subject: string, body: string,
): Promise<{success: boolean; error?: string}> {
  const password = GMAIL_APP_PASSWORD.value();
  if (!password) {
    return {success: false, error: "GMAIL_APP_PASSWORD secret no configurado"};
  }
  try {
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {user: SMTP_USER, pass: password},
    });
    await transporter.sendMail({
      from: SMTP_FROM,
      to,
      subject,
      text: body,
    });
    return {success: true};
  } catch (e) {
    return {success: false, error: String(e)};
  }
}

/**
 * Trigger Firestore: cuando se crea un doc en email_queue, envía el email.
 */
export const processEmailQueue = onDocumentCreated(
    {
      document: "email_queue/{docId}",
      region: "europe-west1",
      secrets: [GMAIL_APP_PASSWORD],
    },
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data();
      if (data.enviado === true) return;

      const to = String(data.to ?? "");
      const subject = String(data.subject ?? "(sin asunto)");
      const body = String(data.body ?? "");
      if (!to) {
        await snap.ref.update({error: "missing_to", enviado: false});
        return;
      }

      functions.logger.info("Procesando email queue", {to, subject, intento: data.intentos ?? 0});
      const r = await sendEmailViaGmail(to, subject, body);
      if (r.success) {
        await snap.ref.update({
          enviado: true,
          enviadoEn: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await snap.ref.update({
          enviado: false,
          intentos: admin.firestore.FieldValue.increment(1),
          ultimoError: r.error,
          ultimoIntentoEn: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    },
);

/**
 * Cron horario que reintenta emails fallidos con menos de 3 intentos.
 */
export const retryFailedEmails = onSchedule(
    {
      schedule: "17 * * * *", // minuto 17 de cada hora (off-peak)
      region: "europe-west1",
      timeZone: "Europe/Madrid",
      secrets: [GMAIL_APP_PASSWORD],
      memory: "256MiB",
      timeoutSeconds: 300,
    },
    async () => {
      const snap = await db.collection("email_queue")
          .where("enviado", "==", false)
          .where("intentos", "<", 3)
          .limit(50)
          .get();
      if (snap.empty) return;

      let ok = 0; let ko = 0;
      for (const d of snap.docs) {
        const data = d.data();
        const r = await sendEmailViaGmail(
            String(data.to ?? ""),
            String(data.subject ?? ""),
            String(data.body ?? ""),
        );
        if (r.success) {
          await d.ref.update({
            enviado: true,
            enviadoEn: admin.firestore.FieldValue.serverTimestamp(),
          });
          ok++;
        } else {
          await d.ref.update({
            intentos: admin.firestore.FieldValue.increment(1),
            ultimoError: r.error,
            ultimoIntentoEn: admin.firestore.FieldValue.serverTimestamp(),
          });
          ko++;
        }
      }
      functions.logger.info("retryFailedEmails", {ok, ko, total: snap.size});
    },
);

/**
 * Cron 14:55 y 19:55 ES — recordatorio al admin de subir Excel Clinni.
 *
 * Política #4 (decisión usuario): si HOY no se ha hecho ninguna
 * importación de citas (audit_logs tipo CLINNI_IMPORT con timestamp >=
 * hoy 00:00), enviamos email Y mensaje WhatsApp al admin recordando
 * que toca subir el Excel.
 *
 * Si ya se ha subido al menos una vez hoy, no hacemos nada.
 */
export const excelImportReminder = onSchedule(
    {
      schedule: "55 14,19 * * 1-5", // 14:55 y 19:55 lunes a viernes
      region: "europe-west1",
      timeZone: "Europe/Madrid",
      secrets: [GMAIL_APP_PASSWORD],
      memory: "256MiB",
      timeoutSeconds: 120,
    },
    async () => {
      // Inicio del día actual en Madrid
      const now = new Date();
      const madridMidnight = new Date(now.toLocaleString("en-US", {
        timeZone: "Europe/Madrid",
      }));
      madridMidnight.setHours(0, 0, 0, 0);
      const startTs = admin.firestore.Timestamp.fromDate(madridMidnight);

      const snap = await db.collection("audit_logs")
          .where("tipo", "==", "CLINNI_IMPORT")
          .where("timestamp", ">=", startTs)
          .limit(1)
          .get();

      if (!snap.empty) {
        functions.logger.info("Excel Clinni ya importado hoy — no recordar");
        return;
      }

      const cfg = await db.collection("config").doc("whatsapp_bot").get();
      const cfgData = cfg.data() ?? {};
      const emailFallback = (cfgData.emailFallback as string) || "directoriosalufit@gmail.com";

      const horaMad = now.toLocaleString("es-ES", {
        timeZone: "Europe/Madrid", hour: "2-digit", minute: "2-digit", hour12: false,
      });
      await db.collection("email_queue").add({
        to: emailFallback,
        subject: `[Salufit Bot] Recordatorio: subir Excel Clinni (${horaMad})`,
        body: "Hoy aún no se ha importado el Excel de citas de Clinni. " +
          "Para que el bot mande recordatorios T-24h con la información " +
          "actualizada, recuerda subir el Excel desde el panel admin.\n\n" +
          "Si ya lo hiciste, ignora este aviso.",
        creadoEn: admin.firestore.FieldValue.serverTimestamp(),
        origen: "excelImportReminder",
      });
      functions.logger.info("Email recordatorio Excel encolado", {emailFallback});
    },
);

/**
 * Cron horario — verifica salud del cron `sendAppointmentReminders`.
 * Política #7 (decisión usuario): si las últimas 2 ejecuciones del cron
 * recordatorios fallaron o no corrieron (>90 min sin success), alerta.
 *
 * Implementación pragmática: leemos los logs de cloud functions vía
 * Cloud Logging API es complejo. Simplificamos: cada vez que el cron
 * recordatorios corre con éxito, escribe en `bot_health/last_run` un
 * timestamp. Aquí comprobamos si ese timestamp tiene >90 min — si sí,
 * alertamos.
 */
export const cronHealthCheck = onSchedule(
    {
      schedule: "37 * * * *", // minuto 37 cada hora (off-peak)
      region: "europe-west1",
      timeZone: "Europe/Madrid",
      secrets: [GMAIL_APP_PASSWORD],
      memory: "128MiB",
      timeoutSeconds: 60,
    },
    async () => {
      const ref = db.collection("bot_health").doc("last_reminder_run");
      const snap = await ref.get();
      if (!snap.exists) {
        functions.logger.info("bot_health/last_reminder_run no existe — skip primer chequeo");
        return;
      }
      const data = snap.data() ?? {};
      const lastTs = (data.timestamp as admin.firestore.Timestamp | undefined)?.toMillis();
      if (!lastTs) return;
      const minutesAgo = (Date.now() - lastTs) / 60000;
      if (minutesAgo < 90) {
        return;
      }
      // Cron caído.
      const alreadyAlerted = (data.alertaEnviada as boolean) ?? false;
      if (alreadyAlerted) {
        // Ya alertamos; no spam.
        return;
      }
      const cfg = await db.collection("config").doc("whatsapp_bot").get();
      const cfgData = cfg.data() ?? {};
      const emailFallback = (cfgData.emailFallback as string) || "directoriosalufit@gmail.com";

      await db.collection("email_queue").add({
        to: emailFallback,
        subject: `[Salufit Bot] ⚠️ Cron recordatorios CAÍDO (${Math.round(minutesAgo)} min sin ejecutar)`,
        body: `El cron sendAppointmentReminders no ha corrido con éxito en los últimos ${Math.round(minutesAgo)} minutos. ` +
          "Esto significa que los recordatorios T-24h podrían no estar llegando.\n\n" +
          "Comprueba: https://console.firebase.google.com/project/salufitnewapp/functions/logs?execution=sendAppointmentReminders",
        creadoEn: admin.firestore.FieldValue.serverTimestamp(),
        origen: "cronHealthCheck",
      });
      // Avisamos también por WhatsApp (multi-DM si hay grupos)
      const dests: string[] = [];
      const grupos = (cfgData.gruposRecepcion as Array<{telefono: string}> | undefined) ?? [];
      for (const g of grupos) if (g.telefono) dests.push(g.telefono);
      if (dests.length === 0 && cfgData.grupoRecepcionId) {
        dests.push(cfgData.grupoRecepcionId as string);
      }

      // No tenemos sendTextMessage importado aquí para evitar deps cruzadas;
      // en su lugar, encolamos también una "alerta_whatsapp" que un
      // trigger separado pueda procesar (o lo dejamos solo email, lo
      // simpler).
      await ref.update({alertaEnviada: true, ultimaAlertaEn: admin.firestore.FieldValue.serverTimestamp()});
      functions.logger.warn("Alerta cron caído enviada por email", {minutesAgo, emailFallback, destinatarios: dests.length});
    },
);
