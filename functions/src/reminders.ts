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
import {sendButtonMessage, sendTemplateMessage, sendTextMessage} from "./whatsapp";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

const WHATSAPP_TOKEN = defineSecret("WHATSAPP_TOKEN");

interface BotConfig {
  whatsappPhoneId: string;
  horasAntelacionRecordatorio: number;
  activo: boolean;
  grupoRecepcionId: string;
}

async function loadConfig(): Promise<BotConfig> {
  try {
    const doc = await db.collection("config").doc("whatsapp_bot").get();
    if (!doc.exists) {
      return {
        whatsappPhoneId: "723362620868862",
        horasAntelacionRecordatorio: 24,
        activo: true,
        grupoRecepcionId: "",
      };
    }
    const data = doc.data() ?? {};
    return {
      whatsappPhoneId: (data.whatsappPhoneId as string) || "723362620868862",
      horasAntelacionRecordatorio:
        (data.horasAntelacionRecordatorio as number) ?? 24,
      activo: data.activo !== false,
      grupoRecepcionId: (data.grupoRecepcionId as string) || "",
    };
  } catch (e) {
    functions.logger.warn("loadConfig failed", e);
    return {
      whatsappPhoneId: "723362620868862",
      horasAntelacionRecordatorio: 24,
      activo: true,
      grupoRecepcionId: "",
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
    // VENTANA DEL CRON — política T-26h a T-2h.
    //
    // Antes era [T-20h, T+48h] que tenía un bug grave: citas con menos
    // de 20h vista NUNCA entraban en ventana, así que cualquier cita
    // del mismo día NO recibía recordatorio.
    //
    // Nueva política: cubre citas entre 2 y 26 horas en el futuro. Un
    // cron cada 30 min asegura que cualquier cita en ese rango entre
    // en ventana al menos una vez. Una cita a las 18:00 hoy:
    //   - Cron 16:00 (anterior): vista 2h → IN
    //   - Cron 16:30: vista 1.5h → fuera
    //   El primer paso ya la pilló y marcó recordatorioEnviado=true.
    //
    // forceWindowHoursStart/End mantenidos para tests manuales.
    const horasIni = opts?.forceWindowHoursStart ?? 2;
    const horasFin = opts?.forceWindowHoursEnd ??
      (config.horasAntelacionRecordatorio + 2);
    const desde = new Date(now.getTime() + horasIni * 60 * 60 * 1000);
    const hasta = new Date(now.getTime() + horasFin * 60 * 60 * 1000);
    functions.logger.info("Ventana recordatorios", {
      horasIni, horasFin,
      desde: desde.toISOString(),
      hasta: hasta.toISOString(),
    });

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

  // ANTI-SPAM duplicados: si un paciente tiene varias citas el mismo
  // día (caso real: 12 pacientes con duplicados), enviamos UN único
  // recordatorio para la cita más temprana y marcamos las otras
  // como "recordatorioEnviado=true + agrupadaConPrimera=true". Recepción
  // recibe un DM avisando para gestionar manualmente las extras.
  const byPatientDay = new Map<string, FirebaseFirestore.QueryDocumentSnapshot[]>();
  for (const doc of docsSnap.docs) {
    const d = doc.data();
    const tel = (d.pacienteTelefono as string) || "";
    const f = (d.fechaCita as admin.firestore.Timestamp).toDate();
    if (!tel) continue;
    const dayMadrid = f.toLocaleString("sv-SE", {
      timeZone: "Europe/Madrid",
    }).slice(0, 10);
    const key = `${tel}_${dayMadrid}`;
    if (!byPatientDay.has(key)) byPatientDay.set(key, []);
    byPatientDay.get(key)!.push(doc);
  }

  // Marcar las "secundarias" (todas las que no son la más temprana)
  // como ya enviadas, y construir lista de "primarias" a procesar.
  const primaryDocs: FirebaseFirestore.QueryDocumentSnapshot[] = [];
  const skippedDuplicates: Array<{telefono: string; nombre: string; citas: string[]}> = [];
  for (const [, group] of byPatientDay) {
    group.sort((a, b) => {
      const ta = (a.data().fechaCita as admin.firestore.Timestamp).toMillis();
      const tb = (b.data().fechaCita as admin.firestore.Timestamp).toMillis();
      return ta - tb;
    });
    primaryDocs.push(group[0]);
    if (group.length > 1) {
      const dup = group.slice(1);
      const ddata = group[0].data();
      const horas = group.map((d) => {
        const f = (d.data().fechaCita as admin.firestore.Timestamp).toDate();
        return f.toLocaleString("es-ES", {
          timeZone: "Europe/Madrid",
          hour: "2-digit", minute: "2-digit", hour12: false,
        });
      });
      skippedDuplicates.push({
        telefono: (ddata.pacienteTelefono as string) || "",
        nombre: (ddata.pacienteNombre as string) || "",
        citas: horas,
      });
      // Marcar las extras como enviadas para que el cron no las re-procese.
      for (const extra of dup) {
        await extra.ref.update({
          recordatorioEnviado: true,
          fechaRecordatorio: admin.firestore.FieldValue.serverTimestamp(),
          agrupadaConPrimera: group[0].id,
          motivoNoNotificacion: "duplicada_misma_persona_mismo_dia",
        });
      }
    }
  }

  if (skippedDuplicates.length > 0) {
    functions.logger.info("Citas duplicadas detectadas", {
      total: skippedDuplicates.length, samples: skippedDuplicates.slice(0, 5),
    });
  }

  for (const doc of primaryDocs) {
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

    // Texto EXACTO del template Meta `recordatorio_cita_v2` (aprobado).
    // Este es el que verá el paciente cuando se envía por template.
    // Lo guardamos en la conversación para que el panel muestre lo real.
    const templateBody =
      `Hola ${nombre || "paciente"}, te recordamos tu cita en Centro Salufit:\n\n` +
      `📅 ${fechaFmt}\n` +
      `💼 ${servicio || "Cita"}\n\n` +
      "Por favor, confirma tu asistencia:";

    // Texto del fallback (texto libre) — solo se usa si el template
    // falla y el paciente ya tiene ventana 24h abierta con el bot.
    const fallbackBody =
      `¡Hola ${nombre}! 👋 Te recordamos tu cita:\n\n` +
      `📅 ${fechaFmt}\n` +
      `💼 ${servicio || "Cita"}\n\n` +
      "¿Nos confirmas que puedes venir?";

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
    let usedTemplate = result.success;

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
          fallbackBody,
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
      // Guardamos el texto que REALMENTE recibió el paciente — depende de
      // si fue por template o por fallback. Antes guardábamos siempre el
      // fallback aunque el envío fuera por template, lo que confundía al
      // panel admin.
      const textoEnviado = usedTemplate ? templateBody : fallbackBody;
      await db.collection("whatsapp_conversations").add({
        pacienteNombre: nombre,
        pacienteTelefono: telefono,
        appointmentId: doc.id,
        tipo: "recordatorio",
        estado: "activa",
        intencionDetectada: null,
        resultado: null,
        viaTemplate: usedTemplate,
        mensajes: [
          {
            rol: "bot",
            texto: textoEnviado,
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

  // Si hay duplicados detectados, avisar al grupo de recepción para
  // que gestione manualmente las citas extra del mismo paciente. El bot
  // solo envió recordatorio para la primera (más temprana) de cada uno.
  if (skippedDuplicates.length > 0 && config.grupoRecepcionId) {
    const lines = [
      "📅 RECORDATORIOS — pacientes con varias citas mismo día",
      "",
      "El bot envió UN recordatorio (la cita más temprana) a estos pacientes.",
      "Las citas extra están marcadas como notificadas para evitar spam.",
      "Llama tú para confirmar las demás:",
      "",
    ];
    for (const dup of skippedDuplicates) {
      lines.push(`👤 ${dup.nombre} · 📞 ${dup.telefono}`);
      lines.push(`   Citas hoy/mañana: ${dup.citas.join(", ")}`);
    }
    try {
      await sendTextMessage(
          {
            phoneId: config.whatsappPhoneId,
            token: waToken,
            to: config.grupoRecepcionId,
          },
          lines.join("\n"),
      );
    } catch (e) {
      functions.logger.warn("Aviso duplicados a recepción falló", e);
    }
  }

  functions.logger.info("Recordatorios procesados", {
    sent, failed, total: docsSnap.size,
    duplicadosAgrupados: skippedDuplicates.length,
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
/**
 * Cron diario que marca como `vencida` las citas con estado="pendiente"
 * cuya fechaCita haya pasado hace más de 6h. Sin esto, una cita olvidada
 * en Clinni quedaría como "pendiente" para siempre y entraría una y otra
 * vez en queries pasadas.
 *
 * Usamos margen de 6h por seguridad: si Clinni y Firestore tienen un
 * desajuste horario (por timezone) o si el profesional aún no ha cerrado
 * la cita en Clinni, no la cerramos en caliente. El cron corre cada
 * madrugada a las 03:00 ES.
 */
async function runExpireAppointments(): Promise<{updated: number}> {
  const cutoff = new Date(Date.now() - 6 * 60 * 60 * 1000);
  const snap = await db
      .collection("clinni_appointments")
      .where("estado", "==", "pendiente")
      .where("fechaCita", "<", admin.firestore.Timestamp.fromDate(cutoff))
      .limit(500)
      .get();

  if (snap.empty) {
    functions.logger.info("Sin citas pendientes vencidas");
    return {updated: 0};
  }

  // Procesar en chunks de 400 (límite Firestore 500/batch).
  let updated = 0;
  for (let i = 0; i < snap.docs.length; i += 400) {
    const chunk = snap.docs.slice(i, i + 400);
    const batch = db.batch();
    for (const doc of chunk) {
      batch.update(doc.ref, {
        estado: "vencida",
        vencidaEn: admin.firestore.FieldValue.serverTimestamp(),
        motivoVencida: "auto_expirada_cron",
      });
      updated++;
    }
    await batch.commit();
  }

  functions.logger.info("Citas auto-vencidas", {updated, scanned: snap.size});
  return {updated};
}

export const expirePastAppointments = onSchedule(
    {
      schedule: "0 3 * * *",
      region: "europe-west1",
      timeZone: "Europe/Madrid",
      memory: "256MiB",
      timeoutSeconds: 540,
    },
    async () => {
      await runExpireAppointments();
    },
);

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
