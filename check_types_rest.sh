#!/bin/zsh

PROJECT_ID="salufitnewapp"
TOKEN=$(firebase auth:print-access-token)

echo "🔍 Consultando Firestore vía REST API..."
echo "--------------------------------------------------"

get_doc() {
  local col=$1
  echo "📂 Colección: $col"
  curl -s -X GET "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents/$col?pageSize=1" \
    -H "Authorization: Bearer $TOKEN" | grep -E "email|historyId|idH|stringValue|integerValue" | head -n 15
  echo "--------------------------------------------------"
}

get_doc "users"
get_doc "legacy_import"
