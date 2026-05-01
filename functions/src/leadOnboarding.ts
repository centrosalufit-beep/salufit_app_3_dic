/**
 * Onboarding de paciente nuevo (Fase B).
 *
 * Cuando llega un mensaje de un número que NO está en `clinni_patients`
 * y muestra interés en pedir cita, el bot lo guía con 3 preguntas y
 * pre-ficha al paciente en `clinni_patients_pending`. Recepción aprueba
 * después desde el panel y la promociona a `clinni_patients`.
 *
 * Estados de la conversación (campo `etapaOnboarding`):
 *   - "preguntando_nombre"       → bot espera respuesta con nombre
 *   - "preguntando_servicio"     → bot espera respuesta con servicio
 *   - "preguntando_preferencia"  → bot espera respuesta con preferencias
 *   - "completado"               → datos recogidos, recepción avisada
 *
 * El detector de intención (sin Claude para ahorrar) busca palabras
 * clave en español/inglés. Si no detecta interés en cita, NO arranca
 * el flujo y deja que el filtro fase 3 mande el mensaje fijo.
 */

import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

export type OnboardingStage =
  | "preguntando_nombre"
  | "preguntando_servicio"
  | "preguntando_preferencia"
  | "completado";

export interface OnboardingState {
  stage: OnboardingStage;
  nombre?: string;
  servicio?: string;
  preferencia?: string;
}

/**
 * Detecta si un primer mensaje (paciente desconocido) muestra interés en
 * pedir cita o información comercial. Si es true, arrancamos onboarding;
 * si false, devolvemos al flujo legacy de "no eres paciente".
 *
 * Heurística sencilla: palabras clave en ES + EN. Si en producción
 * resulta poco preciso, podemos delegar a Claude (más caro).
 */
export function looksLikeAppointmentRequest(texto: string): boolean {
  const t = texto.toLowerCase();
  const keywords = [
    "cita", "appointment", "reserva", "reservar", "agendar", "pedir hora",
    "concertar", "consulta", "primera visita", "información", "informacion",
    "fisio", "fisioterapia", "psicolog", "dental", "dentist", "odonto",
    "podolog", "tratamiento", "sesión", "sesion", "valoración", "valoracion",
    "tarifa", "precio", "cuánto cuesta", "cuanto cuesta", "horario",
    "abierto", "abren", "abrís", "abreis", "cuándo abren",
    "book", "appointment", "info",
  ];
  return keywords.some((k) => t.includes(k));
}

/**
 * Devuelve el mensaje siguiente del bot dado el estado actual y el último
 * mensaje del paciente. NO escribe a Firestore — eso lo hace el caller
 * con la conv ya cargada.
 *
 * @param texto Mensaje recibido (puede ser el inicial que dispara onboarding,
 *              o la respuesta a una pregunta previa).
 * @param current Estado actual (undefined si es el primer mensaje).
 * @param bienvenida Texto del campo bienvenidaNuevoPaciente de clinic_info.
 * @returns { reply, nextState } — texto que debe enviar el bot y el nuevo
 *          estado a guardar en la conv. Si nextState.stage === "completado"
 *          el caller debe crear el doc en clinni_patients_pending y
 *          notificar a recepción.
 */
export function nextOnboardingStep(
    texto: string,
    current: OnboardingState | undefined,
    bienvenida: string,
): {reply: string; nextState: OnboardingState} {
  // Caso 1: arranque
  if (!current) {
    const greeting = bienvenida ||
      "¡Hola! 👋 Te escribe el bot del Centro Salufit.";
    return {
      reply: `${greeting}\n\nPara ayudarte con tu cita necesito tres datos rápidos. ` +
        "Primero, ¿cuál es tu **nombre completo**?",
      nextState: {stage: "preguntando_nombre"},
    };
  }

  // Caso 2: tiene nombre, vamos a servicio
  if (current.stage === "preguntando_nombre") {
    const nombre = texto.trim().slice(0, 80);
    if (!nombre || nombre.length < 3) {
      return {
        reply: "Disculpa, ¿me dices tu nombre completo? (al menos nombre y apellido) 🙂",
        nextState: current,
      };
    }
    const primerNombre = nombre.split(" ")[0];
    return {
      reply: `Encantado, ${primerNombre} 🙂 ` +
        "¿Qué tipo de tratamiento te interesa? (fisio, psicología, " +
        "odontología, podología, otra…)",
      nextState: {stage: "preguntando_servicio", nombre},
    };
  }

  // Caso 3: tiene servicio, vamos a preferencia
  if (current.stage === "preguntando_servicio") {
    const servicio = texto.trim().slice(0, 100);
    if (!servicio) {
      return {
        reply: "¿Qué tratamiento? Una palabra basta (fisio, psico, dental, podología…).",
        nextState: current,
      };
    }
    return {
      reply: "Anotado. Una última cosa para encajarte mejor: " +
        "¿qué días y franjas te van bien?\n\n" +
        "Por favor, dímelo así (puedes combinar):\n" +
        "• Días: lunes, martes, miércoles, jueves, viernes, sábado\n" +
        "• Franja: mañana o tarde\n\n" +
        "Por ejemplo: \"martes mañana y jueves tarde\" o \"cualquier mañana entre semana\".",
      nextState: {
        stage: "preguntando_preferencia",
        nombre: current.nombre,
        servicio,
      },
    };
  }

  // Caso 4: tenemos todo, completamos
  if (current.stage === "preguntando_preferencia") {
    const preferencia = texto.trim().slice(0, 200);
    return {
      reply: "¡Perfecto! Ya tengo lo que necesito. " +
        "Recepción te llama hoy mismo o mañana a primera hora con dos opciones de cita 🙌",
      nextState: {
        stage: "completado",
        nombre: current.nombre,
        servicio: current.servicio,
        preferencia: preferencia || "(sin preferencia indicada)",
      },
    };
  }

  // Estado completado o desconocido — fallback que no arranca un nuevo flujo.
  return {
    reply: "Ya tengo tus datos anotados, recepción te contacta enseguida 🙂",
    nextState: current,
  };
}

/**
 * Crea (o sobrescribe) el doc en clinni_patients_pending. ID = teléfono.
 */
export async function persistPendingPatient(params: {
  telefono: string;
  nombre: string;
  servicioInteres: string;
  preferencia: string;
  conversationId: string;
}): Promise<void> {
  await db.collection("clinni_patients_pending").doc(params.telefono).set({
    nombreCompleto: params.nombre,
    telefono: params.telefono,
    servicioInteres: params.servicioInteres,
    preferenciaHoraria: params.preferencia,
    origen: "whatsapp_bot",
    conversationId: params.conversationId,
    estado: "pendiente_validacion",
    creadoEn: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: false});
}
