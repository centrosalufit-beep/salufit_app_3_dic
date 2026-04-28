/**
 * Helper de clasificación de intención con Claude Haiku 4.5.
 *
 * El bot detecta automáticamente el idioma del mensaje (ES o EN) y
 * responde en el mismo idioma. La intención clasificada se devuelve
 * normalizada (en inglés, código interno) para no depender del idioma
 * del paciente.
 */

import Anthropic from "@anthropic-ai/sdk";
import * as functions from "firebase-functions";

const MODEL = "claude-haiku-4-5-20251001";

export type BotIntent =
  | "confirmar"
  | "cancelar"
  | "reagendar"
  | "consulta"
  | "escalate"
  | "fuera_horario";

export interface ClassificationContext {
  pacienteNombre: string;
  fechaCita: string; // ISO string
  profesional: string;
  servicio: string;
  isWithinBusinessHours: boolean;
}

export interface ClassificationResult {
  intencion: BotIntent;
  respuesta: string;
  confianza: number;
  idiomaDetectado: "es" | "en";
}

const SYSTEM_PROMPT = `Eres el asistente virtual de Centro Salufit, una clínica de fisioterapia y entrenamiento en Calpe (España).

TU TAREA: clasificar el mensaje del paciente en UNA categoría y generar una respuesta breve.

CATEGORÍAS (responde en español, código interno):
- "confirmar": el paciente confirma asistencia a su cita.
- "cancelar": el paciente quiere cancelar su cita.
- "reagendar": el paciente quiere cambiar la fecha/hora de su cita.
- "consulta": pregunta general sobre la clínica, servicios, horarios, ubicación, precios.
- "escalate": tema complejo que requiere un humano (queja, asunto médico complejo, factura, etc.).
- "fuera_horario": SOLO si el sistema indica que el mensaje llega fuera del horario laboral.

REGLAS CRÍTICAS:
1. NO preguntes al paciente qué día ni qué hora prefiere para reagendar. El sistema busca huecos automáticamente y se los enviará con botones.
2. Detecta el idioma del mensaje (ES o EN) y responde en el MISMO idioma del paciente.
3. La respuesta debe ser breve, cordial y profesional (máximo 2 frases).
4. Si la intención es "confirmar", "cancelar" o "reagendar", la respuesta SOLO debe acusar recibo brevemente; el sistema enviará la confirmación final.
5. Si es "consulta", responde con la información disponible o di que no la tienes y pasarás a recepción.
6. NUNCA inventes precios, horarios concretos ni datos médicos.

CONTEXTO DE LA CITA DEL PACIENTE:
- Nombre: {pacienteNombre}
- Cita: {fechaCita}
- Profesional: {profesional}
- Servicio: {servicio}
- Mensaje recibido en horario laboral: {isWithinBusinessHours}

RESPONDE SOLO en formato JSON válido, sin texto adicional fuera del objeto:
{
  "intencion": "confirmar|cancelar|reagendar|consulta|escalate|fuera_horario",
  "respuesta": "...",
  "confianza": 0.95,
  "idiomaDetectado": "es" | "en"
}`;

/**
 * Clasifica un mensaje de paciente y genera respuesta breve.
 * Devuelve `null` si Anthropic falla.
 */
export async function classifyIntent(
    apiKey: string,
    mensaje: string,
    context: ClassificationContext,
): Promise<ClassificationResult | null> {
  try {
    const client = new Anthropic({apiKey});
    const filledPrompt = SYSTEM_PROMPT
        .replace("{pacienteNombre}", context.pacienteNombre || "(desconocido)")
        .replace("{fechaCita}", context.fechaCita || "(sin cita asociada)")
        .replace("{profesional}", context.profesional || "(no asignado)")
        .replace("{servicio}", context.servicio || "(no especificado)")
        .replace(
            "{isWithinBusinessHours}",
            context.isWithinBusinessHours ? "sí" : "no",
        );
    const response = await client.messages.create({
      model: MODEL,
      max_tokens: 400,
      system: filledPrompt,
      messages: [{role: "user", content: mensaje}],
    });

    const block = response.content[0];
    if (!block || block.type !== "text") return null;
    const raw = block.text.trim();

    // Extraer JSON aunque venga con preámbulo
    const jsonMatch = raw.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      functions.logger.warn("Claude no devolvió JSON parseable", {raw});
      return null;
    }
    const parsed = JSON.parse(jsonMatch[0]) as Partial<ClassificationResult>;

    // Validaciones defensivas
    const validIntents: BotIntent[] = [
      "confirmar", "cancelar", "reagendar", "consulta", "escalate", "fuera_horario",
    ];
    if (!parsed.intencion || !validIntents.includes(parsed.intencion as BotIntent)) {
      return null;
    }
    if (!parsed.respuesta || typeof parsed.respuesta !== "string") {
      return null;
    }
    return {
      intencion: parsed.intencion as BotIntent,
      respuesta: parsed.respuesta,
      confianza: typeof parsed.confianza === "number" ? parsed.confianza : 0.8,
      idiomaDetectado: parsed.idiomaDetectado === "en" ? "en" : "es",
    };
  } catch (e) {
    functions.logger.error("Claude classifyIntent error", e);
    return null;
  }
}
