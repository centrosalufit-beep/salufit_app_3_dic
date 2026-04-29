/**
 * Descarga de medios entrantes de WhatsApp (imágenes, documentos, audio,
 * video) y subida a Firebase Storage. Útil sobre todo para justificantes
 * en casos de fuerza mayor (parte médico, etc.).
 *
 * Pipeline:
 *   1. GET https://graph.facebook.com/v23.0/{mediaId} con Bearer token
 *      → JSON con url, mime_type, sha256, file_size, etc.
 *   2. GET de esa url (con Bearer también) → binario.
 *   3. Subir binario a Firebase Storage en
 *      whatsapp_media/{telefono}/{timestamp}_{ext}
 *   4. Devolver URL firmada de 7 días para que recepción la abra.
 *
 * Si algo falla en el camino, devolvemos null y el caller decide qué hacer.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const WHATSAPP_API_VERSION = "v23.0";
const SIGNED_URL_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 días

interface MediaMetadata {
  url: string;
  mime_type: string;
  sha256: string;
  file_size: number;
  id: string;
  messaging_product?: string;
}

export interface StoredMedia {
  storagePath: string;
  signedUrl: string;
  mimeType: string;
  sizeBytes: number;
  filename: string;
}

function extFromMime(mime: string): string {
  const map: Record<string, string> = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "audio/ogg": "ogg",
    "audio/mpeg": "mp3",
    "audio/mp4": "m4a",
    "audio/aac": "aac",
    "video/mp4": "mp4",
    "video/3gpp": "3gp",
    "application/pdf": "pdf",
    "application/msword": "doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
  };
  return map[mime] ?? "bin";
}

export async function fetchMediaAndStore(
    mediaId: string,
    token: string,
    telefono: string,
    suggestedFilename?: string,
): Promise<StoredMedia | null> {
  if (!mediaId) return null;
  try {
    // 1) Metadata de Meta
    const metaResp = await fetch(
        `https://graph.facebook.com/${WHATSAPP_API_VERSION}/${mediaId}`,
        {headers: {"Authorization": `Bearer ${token}`}},
    );
    if (!metaResp.ok) {
      functions.logger.warn("WhatsApp media metadata fetch failed", {
        mediaId,
        status: metaResp.status,
      });
      return null;
    }
    const meta = await metaResp.json() as MediaMetadata;

    // 2) Binario
    const binResp = await fetch(meta.url, {
      headers: {"Authorization": `Bearer ${token}`},
    });
    if (!binResp.ok) {
      functions.logger.warn("WhatsApp media binary fetch failed", {
        mediaId,
        status: binResp.status,
      });
      return null;
    }
    const arrayBuffer = await binResp.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // 3) Subida a Storage
    const ts = Date.now();
    const ext = extFromMime(meta.mime_type);
    const safeName = (suggestedFilename ?? "")
        .replace(/[^a-zA-Z0-9._-]/g, "_")
        .slice(0, 80) ||
      `${ts}.${ext}`;
    const filename = safeName.includes(".") ? safeName : `${safeName}.${ext}`;
    const storagePath = `whatsapp_media/${telefono}/${ts}_${filename}`;

    const bucket = admin.storage().bucket();
    const file = bucket.file(storagePath);
    await file.save(buffer, {
      contentType: meta.mime_type,
      metadata: {
        metadata: {
          mediaId,
          telefono,
          mimeType: meta.mime_type,
          sha256: meta.sha256,
        },
      },
    });

    // 4) URL firmada
    const [signedUrl] = await file.getSignedUrl({
      action: "read",
      expires: Date.now() + SIGNED_URL_TTL_MS,
    });

    return {
      storagePath,
      signedUrl,
      mimeType: meta.mime_type,
      sizeBytes: meta.file_size,
      filename,
    };
  } catch (e) {
    functions.logger.error("fetchMediaAndStore exception", {mediaId, error: String(e)});
    return null;
  }
}
