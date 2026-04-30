/**
 * Inspecciona los components de los templates relevantes para el bot.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/meta_template_detail.js
 */

const {execSync} = require("child_process");

const PROJECT_ID = "salufitnewapp";
const WABA_ID = "1843294496221780";
const API_VERSION = "v23.0";
const TEMPLATES_TO_INSPECT = [
  "recordatorio_cita",
  "recordatorio_cita_politica_v1",
  "gestionar_citas",
  "gestionar_citas_2",
  "recordatorio_wsp_8am",
  "respuesta_webhook",
];

function readSecret(name) {
  return execSync(
      `gcloud secrets versions access latest --secret=${name} --project=${PROJECT_ID}`,
      {encoding: "utf-8"},
  ).trim();
}

async function main() {
  const token = readSecret("WHATSAPP_TOKEN");
  for (const name of TEMPLATES_TO_INSPECT) {
    const url = `https://graph.facebook.com/${API_VERSION}/${WABA_ID}/message_templates?name=${encodeURIComponent(name)}&fields=name,language,status,category,components`;
    const res = await fetch(url, {
      headers: {"Authorization": `Bearer ${token}`},
    });
    const body = await res.json();
    const t = body.data?.[0];
    console.log("=".repeat(70));
    if (!t) {
      console.log(`❌ ${name}: no encontrado`);
      continue;
    }
    console.log(`📋 ${t.name} (${t.language}) — ${t.category} — ${t.status}\n`);
    for (const c of t.components ?? []) {
      console.log(`  [${c.type}]${c.format ? ` ${c.format}` : ""}`);
      if (c.text) console.log(`    text: ${c.text.replace(/\n/g, "\n          ")}`);
      if (c.example) console.log(`    example: ${JSON.stringify(c.example)}`);
      if (c.buttons) {
        c.buttons.forEach((b, i) => {
          console.log(`    button ${i}: type=${b.type} text="${b.text}"${b.url ? ` url=${b.url}` : ""}${b.phone_number ? ` tel=${b.phone_number}` : ""}`);
        });
      }
    }
    console.log("");
  }
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
