/**
 * Crea los 2 templates restantes para el bot WhatsApp de Salufit:
 *
 *  1. `confirmacion_reagendado` — UTILITY informativa que se envía a un
 *     paciente cuando recepción confirma manualmente un cambio de cita
 *     (cierra el bucle del flujo "Cambiar cita"). Sin botones.
 *
 *  2. `cancelacion_aviso` — UTILITY proactiva cuando la clínica cancela
 *     una cita (profesional enfermo, festivo no previsto, etc.). Con
 *     botones quick_reply para reagendar o derivar a recepción.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/meta_create_templates_v2.js
 */

const {execSync} = require("child_process");

const PROJECT_ID = "salufitnewapp";
const WABA_ID = "1843294496221780";
const API_VERSION = "v23.0";

const TEMPLATES = [
  {
    name: "confirmacion_reagendado",
    language: "es",
    category: "UTILITY",
    components: [
      {
        type: "BODY",
        text: "Hola {{1}}, hemos confirmado tu cambio de cita en Centro Salufit:\n\n📅 Nueva fecha: {{2}}\n👤 Profesional: {{3}}\n💼 Servicio: {{4}}\n\nSi necesitas modificarla de nuevo, contáctanos. ¡Hasta pronto!\n\n— SALUFIT",
        example: {
          body_text: [
            [
              "María",
              "lunes, 11 de mayo, 10:30",
              "Ibtissam Benaboura",
              "Fisioterapia",
            ],
          ],
        },
      },
    ],
  },
  {
    name: "cancelacion_aviso",
    language: "es",
    category: "UTILITY",
    components: [
      {
        type: "BODY",
        text: "Hola {{1}}, lamentamos informarte que tu cita del {{2}} con {{3}} ({{4}}) ha sido cancelada por motivos internos del centro.\n\nDisculpa las molestias. Por favor, indícanos cómo prefieres continuar:",
        example: {
          body_text: [
            [
              "María",
              "miércoles 6 de mayo a las 09:00",
              "Ibtissam Benaboura",
              "Fisioterapia",
            ],
          ],
        },
      },
      {
        type: "BUTTONS",
        buttons: [
          {type: "QUICK_REPLY", text: "Reagendar cita"},
          {type: "QUICK_REPLY", text: "Llamar a recepción"},
        ],
      },
    ],
  },
];

function readSecret(name) {
  return execSync(
      `gcloud secrets versions access latest --secret=${name} --project=${PROJECT_ID}`,
      {encoding: "utf-8"},
  ).trim();
}

async function createTemplate(token, tpl) {
  const url = `https://graph.facebook.com/${API_VERSION}/${WABA_ID}/message_templates`;
  console.log(`\n${"═".repeat(70)}`);
  console.log(`📤 POST template "${tpl.name}"`);
  console.log("═".repeat(70));
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(tpl),
  });
  const text = await res.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = {raw: text};
  }
  console.log(`Status: ${res.status}`);
  console.log("Response:", JSON.stringify(body, null, 2));
  if (!res.ok) {
    console.error(`❌ Error creando "${tpl.name}"`);
    return false;
  }
  console.log(`✅ "${tpl.name}" creado — id=${body.id} status=${body.status}`);
  return true;
}

async function main() {
  const token = readSecret("WHATSAPP_TOKEN");
  let okCount = 0;
  for (const tpl of TEMPLATES) {
    const ok = await createTemplate(token, tpl);
    if (ok) okCount++;
  }
  console.log(`\n${"═".repeat(70)}`);
  console.log(`Resumen: ${okCount}/${TEMPLATES.length} templates creados.`);
  console.log("═".repeat(70));
  process.exit(okCount === TEMPLATES.length ? 0 : 1);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
