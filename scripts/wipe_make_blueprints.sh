#!/usr/bin/env bash
# Borra los 17 blueprints exportados de Make.com que contienen secrets en plaintext
# (Anthropic API key, WhatsApp Bearer token, Phone ID).
#
# IMPORTANTE: borrar estos archivos NO rota los tokens. Si los blueprints fueron
# enviados por email, subidos a Drive o sincronizados a iCloud, el secret sigue
# expuesto. Después de ejecutar este script:
#   1. Rota la API key de Anthropic en console.anthropic.com → API Keys → Revoke.
#   2. Rota el Bearer token de WhatsApp en business.facebook.com.
#   3. Vacía la papelera para que el `rm` sea efectivo.
#
# Uso:
#   bash scripts/wipe_make_blueprints.sh           # listar (dry-run)
#   bash scripts/wipe_make_blueprints.sh --commit  # borrar de verdad

set -euo pipefail

DOWNLOADS="${HOME}/Downloads"
COMMIT=${1:-}

FILES=(
  "Recepción respuestas WhatsApp.blueprint.json"
  "Recepción respuestas WhatsApp.blueprint (1).json"
  "Recepción respuestas WhatsApp.blueprint (2).json"
  "Recepción respuestas WhatsApp.blueprint (3).json"
  "Recepción respuestas WhatsApp.blueprint (4).json"
  "Recepcion_respuestas_WhatsApp_v2.json"
  "Recepcion_respuestas_WhatsApp_FINAL.json"
  "escenario_2_recepcion_respuestas.json"
  "escenario_2_recepcion_respuestas (1).json"
  "escenario_2_recepcion_respuestas (2).json"
  "escenario_2_recepcion_respuestas (3).json"
  "escenario_2_recepcion_respuestas (4).json"
  "Verificación Webhook Meta.blueprint.json"
  "verificacion_webhook_meta.json"
  "Escenario 5 - Polling timeouts reagendación.blueprint.json"
  "Integration Google Sheets.blueprint.json"
  "New scenario.blueprint.json"
)

echo "Carpeta objetivo: $DOWNLOADS"
echo

found=0
missing=0
for f in "${FILES[@]}"; do
  path="$DOWNLOADS/$f"
  if [[ -f "$path" ]]; then
    echo "  [encontrado] $f"
    found=$((found + 1))
    if [[ "$COMMIT" == "--commit" ]]; then
      rm -P "$path" && echo "             → borrado con sobreescritura"
    fi
  else
    echo "  [no existe]  $f"
    missing=$((missing + 1))
  fi
done

echo
echo "Encontrados: $found / 17"
echo "No existen:  $missing / 17"

if [[ "$COMMIT" != "--commit" ]]; then
  echo
  echo "Esto fue un dry-run. Para borrar de verdad:"
  echo "  bash scripts/wipe_make_blueprints.sh --commit"
  echo
  echo "Tras borrar, vacía la papelera y ROTA los tokens en Anthropic + Meta."
else
  echo
  echo "Borrado completado. Recuerda ROTAR los tokens (Anthropic + Meta)."
  echo "rm -P sobreescribe los bytes antes de unlink, pero no recupera bloques"
  echo "ya respaldados por Time Machine ni copias en iCloud/Drive."
fi
