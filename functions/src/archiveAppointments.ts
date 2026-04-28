/**
 * Cloud Function `archiveOldAppointments` (onSchedule mensual).
 *
 * Mueve citas con fechaCita < hoy-30d y estado in (completada, cancelada,
 * reagendada) desde `clinni_appointments` a `clinni_appointments_archive_{YYYY_MM}`.
 *
 * Las conversaciones (whatsapp_conversations) NUNCA se borran ni archivan.
 * Idea: la colección activa se mantiene pequeña (<1MB típicamente) y los
 * históricos quedan en colecciones por mes para auditoría.
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

const ARCHIVE_AFTER_DAYS = 30;
const ARCHIVABLE_STATES = ["completada", "cancelada", "reagendada"];

function archiveCollectionName(date: Date): string {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  return `clinni_appointments_archive_${yyyy}_${mm}`;
}

export const archiveOldAppointments = onSchedule(
    {
      // Día 1 de cada mes a las 02:00 hora España
      schedule: "0 2 1 * *",
      region: "europe-southwest1",
      timeZone: "Europe/Madrid",
      memory: "256MiB",
      timeoutSeconds: 540,
    },
    async () => {
      const cutoff = new Date();
      cutoff.setDate(cutoff.getDate() - ARCHIVE_AFTER_DAYS);
      const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

      let totalMoved = 0;
      let cursorMs = 0;

      // Iterar paginando por fecha para no exceder memoria
      while (true) {
        let q = db
            .collection("clinni_appointments")
            .where("fechaCita", "<", cutoffTs)
            .where("estado", "in", ARCHIVABLE_STATES)
            .orderBy("fechaCita")
            .limit(400);
        if (cursorMs > 0) {
          q = q.startAfter(admin.firestore.Timestamp.fromMillis(cursorMs));
        }
        const snap = await q.get();
        if (snap.empty) break;

        // Agrupar por mes destino (cada cita va a la colección de su propio mes)
        const grouped: Record<string, admin.firestore.QueryDocumentSnapshot[]> = {};
        for (const doc of snap.docs) {
          const fecha = (doc.data().fechaCita as admin.firestore.Timestamp).toDate();
          const target = archiveCollectionName(fecha);
          (grouped[target] ??= []).push(doc);
        }

        for (const [target, docs] of Object.entries(grouped)) {
          const batch = db.batch();
          for (const d of docs) {
            const archiveRef = db.collection(target).doc(d.id);
            batch.set(archiveRef, {
              ...d.data(),
              archivedAt: admin.firestore.FieldValue.serverTimestamp(),
              originalCollection: "clinni_appointments",
            });
            batch.delete(d.ref);
          }
          await batch.commit();
          functions.logger.info(`Archivadas ${docs.length} citas → ${target}`);
          totalMoved += docs.length;
        }

        // Avanzar cursor al último elemento
        const last = snap.docs[snap.docs.length - 1];
        const lastTs = (last.data().fechaCita as admin.firestore.Timestamp).toMillis();
        if (lastTs <= cursorMs) break; // safety
        cursorMs = lastTs;

        if (snap.size < 400) break;
      }

      functions.logger.info("archiveOldAppointments terminado", {totalMoved});
    },
);
