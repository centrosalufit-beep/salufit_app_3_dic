/**
 * Descubre el WABA ID (WhatsApp Business Account ID) asociado al phoneId
 * que usa el bot, y verifica los scopes del WHATSAPP_TOKEN haciendo una
 * lectura mínima.
 *
 * Lee el secret WHATSAPP_TOKEN via `gcloud secrets versions access` y hace:
 *   1. GET /{phoneId}?fields=whatsapp_business_account → WABA ID.
 *   2. GET /{wabaId}/message_templates?limit=1 → verifica scope de management.
 *
 * Solo lectura. NO crea ni modifica nada en Meta.
 *
 * Uso:
 *   NODE_PATH=$(pwd)/functions/node_modules node scripts/discover_meta_waba.js
 */

const {execSync} = require("child_process");

const PROJECT_ID = "salufitnewapp";
const PHONE_ID = "723362620868862";
const API_VERSION = "v23.0";

function readSecret(name) {
  const cmd = `gcloud secrets versions access latest --secret=${name} --project=${PROJECT_ID}`;
  return execSync(cmd, {encoding: "utf-8"}).trim();
}

async function getJson(url, token) {
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
  return {status: res.status, ok: res.ok, body};
}

async function main() {
  console.log("Leyendo WHATSAPP_TOKEN del Secret Manager...");
  const token = readSecret("WHATSAPP_TOKEN");
  console.log(`  Token (primeros 12 chars): ${token.slice(0, 12)}...`);
  console.log(`  Token length: ${token.length}\n`);

  // 1) Phone Id metadata (campos básicos primero)
  console.log("1) GET /{phoneId} (campos básicos) ...");
  const phoneUrl = `https://graph.facebook.com/${API_VERSION}/${PHONE_ID}?fields=display_phone_number,verified_name,quality_rating`;
  const phoneRes = await getJson(phoneUrl, token);
  console.log(`   Status: ${phoneRes.status}`);
  console.log(`   Body: ${JSON.stringify(phoneRes.body, null, 2)}\n`);

  // 1b) debug_token para descubrir el target (incluye WABA si el token es System User)
  console.log("1b) GET /debug_token?input_token={token} ...");
  const debugUrl = `https://graph.facebook.com/${API_VERSION}/debug_token?input_token=${encodeURIComponent(token)}`;
  const debugRes = await getJson(debugUrl, token);
  console.log(`   Status: ${debugRes.status}`);
  console.log(`   Body: ${JSON.stringify(debugRes.body, null, 2)}\n`);

  // 1c) /me endpoint
  console.log("1c) GET /me ...");
  const meUrl = `https://graph.facebook.com/${API_VERSION}/me`;
  const meRes = await getJson(meUrl, token);
  console.log(`   Status: ${meRes.status}`);
  console.log(`   Body: ${JSON.stringify(meRes.body, null, 2)}\n`);

  // 1d) Probar endpoints específicos para descubrir WABA ID
  const userId = debugRes.body?.data?.user_id;
  const appId = debugRes.body?.data?.app_id;
  console.log(`Pista: user_id=${userId}, app_id=${appId}\n`);

  console.log("1d) GET /{phone_id}/whatsapp_business_accounts ...");
  const phoneWabaUrl = `https://graph.facebook.com/${API_VERSION}/${PHONE_ID}/whatsapp_business_accounts`;
  const r1 = await getJson(phoneWabaUrl, token);
  console.log(`   Status: ${r1.status}, Body: ${JSON.stringify(r1.body)}\n`);

  console.log("1e) GET /{app_id}/whatsapp_business_accounts ...");
  const appWabaUrl = `https://graph.facebook.com/${API_VERSION}/${appId}/whatsapp_business_accounts`;
  const r2 = await getJson(appWabaUrl, token);
  console.log(`   Status: ${r2.status}, Body: ${JSON.stringify(r2.body)}\n`);

  console.log("1f) GET /{user_id}/owned_whatsapp_business_accounts ...");
  const userOwnedUrl = `https://graph.facebook.com/${API_VERSION}/${userId}/owned_whatsapp_business_accounts`;
  const r3 = await getJson(userOwnedUrl, token);
  console.log(`   Status: ${r3.status}, Body: ${JSON.stringify(r3.body)}\n`);

  console.log("1g) GET /{user_id}/assigned_whatsapp_business_accounts ...");
  const userAssignedUrl = `https://graph.facebook.com/${API_VERSION}/${userId}/assigned_whatsapp_business_accounts`;
  const r4 = await getJson(userAssignedUrl, token);
  console.log(`   Status: ${r4.status}, Body: ${JSON.stringify(r4.body)}\n`);

  // Intentar extraer un WABA ID válido
  let wabaId =
    r1.body?.data?.[0]?.id ??
    r2.body?.data?.[0]?.id ??
    r3.body?.data?.[0]?.id ??
    r4.body?.data?.[0]?.id;

  if (!wabaId) {
    console.error("⚠️ No pude descubrir el WABA ID automáticamente.");
    console.error("   Por favor pásame el ID desde Meta Business Manager.");
    process.exit(1);
  }
  console.log(`✅ WABA ID descubierto: ${wabaId}\n`);

  // 2) Listar templates existentes (scope management check)
  console.log("2) GET /{wabaId}/message_templates?limit=5 ...");
  const tplUrl = `https://graph.facebook.com/${API_VERSION}/${wabaId}/message_templates?limit=5&fields=name,language,status,category`;
  const tplRes = await getJson(tplUrl, token);
  console.log(`   Status: ${tplRes.status}`);
  if (!tplRes.ok) {
    console.error("❌ El token NO tiene scope whatsapp_business_management. No podemos crear templates programáticamente.");
    console.error("   Body:", JSON.stringify(tplRes.body, null, 2));
    console.error("\n   Solución: regenerar el token con scope management (en Meta Business Manager → System Users → Add Asset → WhatsApp Account → Manage).");
    process.exit(1);
  }
  console.log("✅ Token tiene scope de management.");
  console.log(`   Templates existentes (${tplRes.body.data?.length ?? 0}):`);
  (tplRes.body.data ?? []).forEach((t) => {
    console.log(`     - ${t.name} (${t.language}) status=${t.status} category=${t.category}`);
  });

  console.log("\n🎉 Listo para crear templates. WABA ID:", wabaId);
  process.exit(0);
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
