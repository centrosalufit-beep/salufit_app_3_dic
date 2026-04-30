/**
 * Crea un template de WhatsApp Business Cloud API.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/meta_create_template.js
 */

const {execSync} = require("child_process");

const PROJECT_ID = "salufitnewapp";
const WABA_ID = "1843294496221780";
const API_VERSION = "v23.0";

const TEMPLATE = {
  name: "recordatorio_cita_v2",
  language: "es",
  category: "UTILITY",
  components: [
    {
      type: "BODY",
      text: "Hola {{1}}, te recordamos tu cita en Centro Salufit:\n\n📅 {{2}}\n💼 {{3}}\n\nPor favor, confirma tu asistencia:",
      example: {
        body_text: [["María", "sábado, 2 de mayo, 09:00", "Fisioterapia"]],
      },
    },
    {
      type: "BUTTONS",
      buttons: [
        {type: "QUICK_REPLY", text: "Confirmar"},
        {type: "QUICK_REPLY", text: "Cambiar cita"},
        {type: "QUICK_REPLY", text: "Cancelar"},
      ],
    },
  ],
};

function readSecret(name) {
  return execSync(
      `gcloud secrets versions access latest --secret=${name} --project=${PROJECT_ID}`,
      {encoding: "utf-8"},
  ).trim();
}

async function main() {
  const token = readSecret("WHATSAPP_TOKEN");
  const url = `https://graph.facebook.com/${API_VERSION}/${WABA_ID}/message_templates`;
  console.log(`POST ${url}`);
  console.log("Body:", JSON.stringify(TEMPLATE, null, 2));
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(TEMPLATE),
  });
  const text = await res.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = {raw: text};
  }
  console.log(`\nStatus: ${res.status}`);
  console.log("Response:", JSON.stringify(body, null, 2));

  if (!res.ok) {
    console.error("\n❌ Error creando template");
    process.exit(1);
  }
  console.log(`\n✅ Template "${TEMPLATE.name}" creado.`);
  console.log(`   id: ${body.id}`);
  console.log(`   status inicial: ${body.status}`);
  console.log(`   category: ${body.category}`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
