/**
 * WhatsApp Cloud API helpers para el bot de Salufit.
 *
 * Funciones reutilizables para enviar mensajes (texto + interactivos)
 * y validar la firma HMAC SHA-256 de los webhooks de Meta.
 */

import * as crypto from "crypto";
import * as functions from "firebase-functions";

// Versión del Graph API de Meta para llamadas salientes. Meta entrega los webhooks
// entrantes en v23.0 (configurado en developers.facebook.com → Webhooks). Mantenemos
// la misma versión saliente para coherencia. Las versiones son retrocompatibles
// dentro del mismo año.
const WHATSAPP_API_VERSION = "v23.0";

interface WhatsAppButton {
  id: string;
  title: string; // Máx 20 caracteres
}

interface SendOptions {
  phoneId: string;
  token: string;
  to: string; // Número con prefijo, ej "34629011055"
}

/**
 * Envía un mensaje de texto plano.
 */
export async function sendTextMessage(
    options: SendOptions,
    body: string,
): Promise<{success: boolean; error?: string; messageId?: string}> {
  const url = `https://graph.facebook.com/${WHATSAPP_API_VERSION}/${options.phoneId}/messages`;
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${options.token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to: options.to,
        type: "text",
        text: {body},
      }),
    });
    const data = await response.json() as {
      messages?: Array<{id: string}>;
      error?: {message: string};
    };
    if (!response.ok) {
      functions.logger.warn("WhatsApp text send failed", {
        status: response.status,
        error: data.error,
        to: options.to,
      });
      return {success: false, error: data.error?.message ?? `HTTP ${response.status}`};
    }
    return {success: true, messageId: data.messages?.[0]?.id};
  } catch (e) {
    functions.logger.error("WhatsApp text send exception", e);
    return {success: false, error: String(e)};
  }
}

/**
 * Envía un mensaje interactivo con botones (máx 3).
 * El `id` de cada botón se devuelve cuando el usuario lo pulsa,
 * en `interactive.button_reply.id` del webhook entrante.
 */
export async function sendButtonMessage(
    options: SendOptions,
    body: string,
    buttons: WhatsAppButton[],
): Promise<{success: boolean; error?: string; messageId?: string}> {
  if (buttons.length === 0 || buttons.length > 3) {
    return {success: false, error: "WhatsApp permite 1-3 botones"};
  }
  const url = `https://graph.facebook.com/${WHATSAPP_API_VERSION}/${options.phoneId}/messages`;
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${options.token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to: options.to,
        type: "interactive",
        interactive: {
          type: "button",
          body: {text: body},
          action: {
            buttons: buttons.map((b) => ({
              type: "reply",
              reply: {id: b.id, title: b.title.slice(0, 20)},
            })),
          },
        },
      }),
    });
    const data = await response.json() as {
      messages?: Array<{id: string}>;
      error?: {message: string};
    };
    if (!response.ok) {
      functions.logger.warn("WhatsApp button send failed", {
        status: response.status,
        error: data.error,
        to: options.to,
      });
      return {success: false, error: data.error?.message ?? `HTTP ${response.status}`};
    }
    return {success: true, messageId: data.messages?.[0]?.id};
  } catch (e) {
    functions.logger.error("WhatsApp button send exception", e);
    return {success: false, error: String(e)};
  }
}

/**
 * Envía un mensaje basado en un template aprobado por Meta. Permite
 * mandar mensajes proactivos a usuarios que NO han escrito al bot en las
 * últimas 24h (la regla de la ventana de servicio de WhatsApp Business).
 *
 * @param templateName Nombre del template aprobado (case-sensitive).
 * @param languageCode Código de idioma (ej. "es", "en_US").
 * @param bodyParams Parámetros que rellenan {{1}}, {{2}}, ... del body
 *                   IGUAL que en el template. ORDEN IMPORTA.
 *                   Si el template usa named_params, pasar como
 *                   `{name: "nombre", value: "..."}` en su lugar.
 */
export async function sendTemplateMessage(
    options: SendOptions,
    templateName: string,
    languageCode: string,
    bodyParams: string[],
): Promise<{success: boolean; error?: string; messageId?: string}> {
  const url = `https://graph.facebook.com/${WHATSAPP_API_VERSION}/${options.phoneId}/messages`;
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${options.token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to: options.to,
        type: "template",
        template: {
          name: templateName,
          language: {code: languageCode},
          components: bodyParams.length > 0 ? [
            {
              type: "body",
              parameters: bodyParams.map((p) => ({type: "text", text: p})),
            },
          ] : [],
        },
      }),
    });
    const data = await response.json() as {
      messages?: Array<{id: string}>;
      error?: {message: string};
    };
    if (!response.ok) {
      functions.logger.warn("WhatsApp template send failed", {
        templateName,
        status: response.status,
        error: data.error,
        to: options.to,
      });
      return {success: false, error: data.error?.message ?? `HTTP ${response.status}`};
    }
    return {success: true, messageId: data.messages?.[0]?.id};
  } catch (e) {
    functions.logger.error("WhatsApp template send exception", e);
    return {success: false, error: String(e)};
  }
}

/**
 * Valida la firma X-Hub-Signature-256 de un webhook entrante de Meta.
 * Si la firma no coincide, el webhook debe rechazarse con 401.
 *
 * @param appSecret App Secret de Meta Business (en Secret Manager)
 * @param signatureHeader Valor del header `x-hub-signature-256`, ej: "sha256=abcd..."
 * @param rawBody Body crudo de la petición (string), NO el JSON parseado
 */
export function validateMetaSignature(
    appSecret: string,
    signatureHeader: string | undefined,
    rawBody: string,
): boolean {
  if (!signatureHeader || !signatureHeader.startsWith("sha256=")) {
    return false;
  }
  const expectedSignature = signatureHeader.slice("sha256=".length);
  const computed = crypto
      .createHmac("sha256", appSecret)
      .update(rawBody, "utf8")
      .digest("hex");
  // Comparación constante-tiempo para evitar ataques de timing
  if (expectedSignature.length !== computed.length) return false;
  return crypto.timingSafeEqual(
      Buffer.from(expectedSignature, "hex"),
      Buffer.from(computed, "hex"),
  );
}

/**
 * Normaliza un número de teléfono al formato E.164 sin '+' (ej: "34629011055").
 * Acepta "+34 629 011 055", "0034629011055", "629011055" (asume España).
 */
export function normalizePhone(input: string): string {
  let p = input.replace(/[\s+\-()]/g, "");
  if (p.startsWith("00")) p = p.slice(2);
  if (p.length === 9 && /^[6-9]/.test(p)) {
    // Móvil/fijo español sin prefijo internacional
    p = "34" + p;
  }
  return p;
}
