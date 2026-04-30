/**
 * Lista los templates existentes en el WABA + verifica scope management.
 * Solo lectura.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/meta_templates_list.js
 */

const {execSync} = require("child_process");

const PROJECT_ID = "salufitnewapp";
const WABA_ID = "1843294496221780";
const API_VERSION = "v23.0";

function readSecret(name) {
  return execSync(
      `gcloud secrets versions access latest --secret=${name} --project=${PROJECT_ID}`,
      {encoding: "utf-8"},
  ).trim();
}

async function main() {
  const token = readSecret("WHATSAPP_TOKEN");
  const url = `https://graph.facebook.com/${API_VERSION}/${WABA_ID}/message_templates?limit=50&fields=name,language,status,category,components`;
  const res = await fetch(url, {
    headers: {"Authorization": `Bearer ${token}`},
  });
  const text = await res.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = {raw: text};
  }
  console.log(`Status: ${res.status}`);
  if (!res.ok) {
    console.error("❌ Error:");
    console.error(JSON.stringify(body, null, 2));
    process.exit(1);
  }
  const templates = body.data ?? [];
  console.log(`✅ Token tiene management sobre WABA ${WABA_ID}`);
  console.log(`Templates existentes: ${templates.length}\n`);
  templates.forEach((t) => {
    console.log(`  - ${t.name} (${t.language})  status=${t.status}  category=${t.category}`);
  });
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
