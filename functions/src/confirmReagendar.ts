/**
 * Cloud Function `sendReagendarConfirmation` (onRequest, admin-only).
 *
 * Llamada desde el panel Windows cuando recepción ha actualizado Clinni
 * y quiere notificar al paciente vía WhatsApp que su reagendamiento
 * está confirmado. Usa el template Meta `confirmacion_reagendado`
 * (UTILITY) para poder mandar fuera de la ventana 24h.
 *
 * Flujo esperado:
 *  1. Paciente pulsa slot en bot → conversación queda en estado
 *     `reagendar_confirmacion_pendiente` con `slotSeleccionado` guardado.
 *  2. Recepción ve el DM y mueve la cita en Clinni manualmente.
 *  3. Recepción abre el panel y, en la conversación, pulsa
 *     "Confirmar y avisar al paciente" → este endpoint.
 *  4. Paciente recibe template informativo + se cierra la conversación.
 */

import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {sendTemplateMessage} from "./whatsapp";

const WHATSAPP_TOKEN = defineSecret("WHATSAPP_TOKEN");

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

interface ConfigShape {
  whatsappPhoneId: string;
}

async function loadPhoneId(): Promise<string> {
  try {
    const doc = await db.collection("config").doc("whatsapp_bot").get();
    const data = (doc.data() ?? {}) as Partial<ConfigShape>;
    return data.whatsappPhoneId || "723362620868862";
  } catch {
    return "723362620868862";
  }
}

async function verifyAdmin(
    req: import("firebase-functions/v2/https").Request,
    res: import("express").Response,
): Promise<string | null> {
  const authHeader = req.headers.authorization ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    res.status(401).json({error: "Falta Authorization Bearer token"});
    return null;
  }
  const idToken = authHeader.substring("Bearer ".length).trim();
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    const userDoc = await db.collection("users_app").doc(decoded.uid).get();
    const rol = ((userDoc.data()?.rol as string) ?? "").toLowerCase();
    if (!["admin", "administrador"].includes(rol)) {
      res.status(403).json({error: "Solo admin puede invocar"});
      return null;
    }
    return decoded.uid;
  } catch {
    res.status(401).json({error: "Token inválido o expirado"});
    return null;
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

export const sendReagendarConfirmation = onRequest(
    {
      region: "europe-southwest1",
      secrets: [WHATSAPP_TOKEN],
      memory: "256MiB",
      timeoutSeconds: 30,
      cors: true,
    },
    async (req, res) => {
      try {
        if (req.method !== "POST") {
          res.status(405).json({error: "Solo POST"});
          return;
        }
        const callerUid = await verifyAdmin(req, res);
        if (!callerUid) return;

        const {conversationId} = (req.body ?? {}) as {
          conversationId?: string;
        };
        if (!conversationId) {
          res.status(400).json({error: "Falta conversationId"});
          return;
        }

        const convRef = db.collection("whatsapp_conversations")
            .doc(conversationId);
        const convSnap = await convRef.get();
        if (!convSnap.exists) {
          res.status(404).json({error: "Conversación no encontrada"});
          return;
        }
        const conv = convSnap.data() ?? {};
        const slot = conv.slotSeleccionado as {
          inicio?: admin.firestore.Timestamp;
          profesionalNombre?: string;
        } | undefined;
        if (!slot?.inicio) {
          res.status(400).json({
            error: "La conversación no tiene slotSeleccionado registrado",
          });
          return;
        }

        const nombre = (conv.pacienteNombre as string) || "";
        const telefono = (conv.pacienteTelefono as string) || "";
        const servicio = (conv.servicio as string) ||
          (conv.intencionDetectada === "reagendar" ? "Cita" : "Cita");
        const profesionalNombre = slot.profesionalNombre ||
          (conv.profesional as string) || "tu profesional";
        const fechaFmt = formatFecha(slot.inicio.toDate());

        if (!telefono) {
          res.status(400).json({error: "La conversación no tiene teléfono"});
          return;
        }

        const result = await sendTemplateMessage(
            {
              phoneId: await loadPhoneId(),
              token: WHATSAPP_TOKEN.value(),
              to: telefono,
            },
            "confirmacion_reagendado",
            "es",
            [
              nombre.split(" ")[0] || nombre || "paciente",
              fechaFmt,
              profesionalNombre,
              servicio,
            ],
        );

        if (!result.success) {
          functions.logger.warn("Template confirmacion_reagendado falló", {
            convId: conversationId,
            error: result.error,
          });
          res.status(502).json({error: result.error ?? "Meta API error"});
          return;
        }

        await convRef.update({
          estado: "resuelta",
          resultado: "reagendar_confirmado_por_recepcion",
          confirmadaPor: callerUid,
          confirmadaEn: admin.firestore.FieldValue.serverTimestamp(),
          fechaUltimaInteraccion: admin.firestore.FieldValue.serverTimestamp(),
          mensajes: admin.firestore.FieldValue.arrayUnion({
            rol: "bot",
            texto: `(template confirmacion_reagendado: ${fechaFmt} con ${profesionalNombre})`,
            timestamp: admin.firestore.Timestamp.now(),
          }),
        });

        await db.collection("audit_logs").add({
          tipo: "WHATSAPP_REAGENDAR_CONFIRMED",
          userId: callerUid,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
            conversationId,
            telefono,
            slotInicio: slot.inicio,
            profesionalNombre,
          },
          status: "SUCCESS",
        });

        res.status(200).json({
          success: true,
          messageId: result.messageId,
        });
      } catch (e) {
        functions.logger.error("sendReagendarConfirmation exception", e);
        res.status(500).json({error: String(e)});
      }
    },
);
