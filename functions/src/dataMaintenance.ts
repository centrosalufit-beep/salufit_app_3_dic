/**
 * Crons de mantenimiento de datos antiguos.
 *
 * #20 archivar conversaciones >6 meses → mueve a `whatsapp_conversations_archive_YYYY_MM`
 * #21 borrar `whatsapp_processed_messages` >30 días (idempotencia ya no necesaria)
 *
 * Diseño coherente con `archiveOldAppointments`: los datos no se pierden,
 * se mueven a colecciones por mes para auditoría futura. Los `processed_messages`
 * SÍ se borran (no aportan valor histórico, son solo flags de idempotencia
 * para webhooks de Meta — solo necesarios mientras Meta puede reintentar
 * mensajes recientes).
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

function archiveCollectionName(date: Date, base: string): string {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  return `${base}_${yyyy}_${mm}`;
}

/**
 * #20 — Archivar conversaciones WhatsApp >6 meses.
 * Cron mensual día 2 a las 03:00 ES.
 */
export const archiveOldConversations = onSchedule(
    {
      schedule: "0 3 2 * *",
      region: "europe-west1",
      timeZone: "Europe/Madrid",
      memory: "256MiB",
      timeoutSeconds: 540,
    },
    async () => {
      const cutoff = new Date();
      cutoff.setMonth(cutoff.getMonth() - 6);
      const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

      let totalMoved = 0;
      let cursorMs = 0;
      while (true) {
        let q = db.collection("whatsapp_conversations")
            .where("fechaUltimaInteraccion", "<", cutoffTs)
            .orderBy("fechaUltimaInteraccion")
            .limit(400);
        if (cursorMs > 0) {
          q = q.startAfter(admin.firestore.Timestamp.fromMillis(cursorMs));
        }
        const snap = await q.get();
        if (snap.empty) break;

        // Agrupar por mes destino
        const grouped: Record<string, admin.firestore.QueryDocumentSnapshot[]> = {};
        for (const doc of snap.docs) {
          const fecha = (doc.data().fechaUltimaInteraccion as admin.firestore.Timestamp)
              .toDate();
          const target = archiveCollectionName(fecha, "whatsapp_conversations_archive");
          (grouped[target] ??= []).push(doc);
        }

        for (const [target, docs] of Object.entries(grouped)) {
          const batch = db.batch();
          for (const doc of docs) {
            const data = doc.data();
            batch.set(db.collection(target).doc(doc.id), {
              ...data,
              archivedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            batch.delete(doc.ref);
            totalMoved++;
          }
          await batch.commit();
        }

        const last = snap.docs[snap.docs.length - 1];
        cursorMs = (last.data().fechaUltimaInteraccion as admin.firestore.Timestamp).toMillis();
        if (snap.size < 400) break;
      }

      functions.logger.info("archiveOldConversations terminado", {totalMoved});
    },
);

/**
 * #21 — Borrar whatsapp_processed_messages > 30 días.
 * Cron semanal domingo 04:00 ES.
 */
export const cleanupProcessedMessages = onSchedule(
    {
      schedule: "0 4 * * 0",
      region: "europe-west1",
      timeZone: "Europe/Madrid",
      memory: "256MiB",
      timeoutSeconds: 540,
    },
    async () => {
      const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);
      let totalDeleted = 0;

      while (true) {
        const snap = await db.collection("whatsapp_processed_messages")
            .where("processedAt", "<", cutoffTs)
            .limit(400)
            .get();
        if (snap.empty) break;

        const batch = db.batch();
        for (const doc of snap.docs) {
          batch.delete(doc.ref);
          totalDeleted++;
        }
        await batch.commit();

        if (snap.size < 400) break;
      }

      functions.logger.info("cleanupProcessedMessages terminado", {totalDeleted});
    },
);
