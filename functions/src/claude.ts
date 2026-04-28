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
  horasHastaCita: number; // negativo si la cita ya pasó, Infinity si no hay cita
}

export interface ClassificationResult {
  intencion: BotIntent;
  respuesta: string;
  confianza: number;
  idiomaDetectado: "es" | "en";
  dentro48h: boolean; // true si quedan menos de 48h (relevante para cancelaciones)
}

// Teléfono de la clínica (recepción humana) que damos al paciente cuando hay
// que escalar/reagendar. NO confundir con el número del bot (+34 672 73 41 31),
// que es el remitente de los mensajes y no se debe dar como contacto humano.
const TELEFONO_RECEPCION = "+34 629 01 10 55";

const SYSTEM_PROMPT = `Eres el asistente virtual de Centro Salufit, una clínica de fisioterapia y entrenamiento en Calpe (España).

TU TAREA: clasificar el mensaje del paciente en UNA categoría y generar una respuesta breve.

CATEGORÍAS (responde en español, código interno):
- "confirmar": el paciente confirma asistencia a su cita.
- "cancelar": el paciente quiere cancelar su cita.
- "reagendar": el paciente quiere cambiar la fecha/hora de su cita.
- "consulta": pregunta general sobre la clínica, servicios, horarios, ubicación, precios.
- "escalate": tema complejo, queja, lenguaje agresivo/insultante, asunto médico complejo, factura, etc.
- "fuera_horario": SOLO si el sistema indica que el mensaje llega fuera del horario laboral.

POLÍTICA DE CANCELACIÓN SALUFIT (REGLA DE NEGOCIO CRÍTICA):
- Si faltan MÁS de 48h para la cita (dentro_48h=false): cancelación gratuita.
- Si faltan MENOS de 48h para la cita (dentro_48h=true): no se puede cancelar gratis.
  El paciente puede REAGENDAR (gratis, máximo 2 veces) o ABONAR 50€ por Bizum
  al ${TELEFONO_RECEPCION} (recepción Salufit).
- El sistema te indica las horas exactas que faltan; usa ese valor para fijar dentro_48h.
- Si el paciente quiere cancelar dentro de 48h, explícale la política con tacto, ofrécele
  reagendar o el Bizum, y devuelve intencion="cancelar" con dentro_48h=true. NO confirmes la
  cancelación: la decisión final la toma recepción.

REGLAS CRÍTICAS:
1. NO preguntes al paciente qué día ni qué hora prefiere para reagendar. El sistema busca huecos
   automáticamente y se los enviará con botones. Si no puedes ofrecer huecos en este turno, indica
   que recepción contactará desde el ${TELEFONO_RECEPCION}.
2. Detecta el idioma del mensaje (ES o EN) y responde en el MISMO idioma del paciente.
   En la respuesta al paciente puedes traducir el teléfono y la política, pero el JSON va en ES.
3. La respuesta debe ser breve, cordial, profesional pero cercana y humana (máximo 3 líneas).
4. Si la intención es "confirmar" la respuesta agradece y recuerda fecha/hora/profesional.
5. Si la intención es "reagendar" la respuesta solo acusa recibo y dice que recepción contacta.
6. Si es "consulta", responde con la información disponible o di que no la tienes y pasarás a
   recepción si es algo complejo.
7. NUNCA inventes precios, horarios concretos ni datos médicos.
8. Si el paciente está frustrado, agresivo o insulta, intencion="escalate", empatiza, discúlpate
   sinceramente e indica que se transfiere a una persona de recepción para atenderle mejor.
9. Firma "SALUFIT" al final cuando proceda. Máximo 1-2 emojis por mensaje, sin abusar.

CONTEXTO DE LA CITA DEL PACIENTE:
- Nombre: {pacienteNombre}
- Cita: {fechaCita}
- Horas restantes hasta la cita: {horasHastaCita}
- Profesional: {profesional}
- Servicio: {servicio}
- Mensaje recibido en horario laboral: {isWithinBusinessHours}

RESPONDE SOLO en formato JSON válido, sin texto adicional, sin markdown, sin \`\`\`. La respuesta
COMPLETA debe empezar con { y terminar con }:
{
  "intencion": "confirmar|cancelar|reagendar|consulta|escalate|fuera_horario",
  "respuesta": "...",
  "confianza": 0.95,
  "idiomaDetectado": "es" | "en",
  "dentro_48h": true | false
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
    const horasStr = !isFinite(context.horasHastaCita) ?
      "(sin cita asociada)" :
      context.horasHastaCita < 0 ?
        `(la cita ya pasó hace ${Math.abs(Math.round(context.horasHastaCita))}h)` :
        `${Math.round(context.horasHastaCita)}h`;
    const filledPrompt = SYSTEM_PROMPT
        .replace("{pacienteNombre}", context.pacienteNombre || "(desconocido)")
        .replace("{fechaCita}", context.fechaCita || "(sin cita asociada)")
        .replace("{horasHastaCita}", horasStr)
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
    // Quitar wrappers ```json ... ``` por si Claude los añade (ocurre a veces)
    const raw = block.text
        .trim()
        .replace(/^```json\s*/i, "")
        .replace(/^```\s*/i, "")
        .replace(/```$/i, "")
        .trim();

    // Extraer JSON aunque venga con preámbulo
    const jsonMatch = raw.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      functions.logger.warn("Claude no devolvió JSON parseable", {raw});
      return null;
    }
    // El blueprint usaba snake_case (dentro_48h); aceptamos ambos.
    type RawResult = Partial<ClassificationResult> & {dentro_48h?: boolean};
    const parsed = JSON.parse(jsonMatch[0]) as RawResult;

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
    // Calculamos dentro48h en código (más fiable que confiar en la IA), pero si la IA
    // lo afirma con cita asociada, lo respetamos.
    const aiDentro48h = parsed.dentro48h ?? parsed.dentro_48h;
    const codeDentro48h = isFinite(context.horasHastaCita) &&
        context.horasHastaCita >= 0 &&
        context.horasHastaCita < 48;
    return {
      intencion: parsed.intencion as BotIntent,
      respuesta: parsed.respuesta,
      confianza: typeof parsed.confianza === "number" ? parsed.confianza : 0.8,
      idiomaDetectado: parsed.idiomaDetectado === "en" ? "en" : "es",
      dentro48h: typeof aiDentro48h === "boolean" ? aiDentro48h : codeDentro48h,
    };
  } catch (e) {
    functions.logger.error("Claude classifyIntent error", e);
    return null;
  }
}
