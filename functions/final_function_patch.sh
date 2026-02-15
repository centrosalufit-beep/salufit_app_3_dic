#!/bin/zsh
FILE="src/index.ts"

echo "🎯 Asegurando que la búsqueda use el ID normalizado..."

# 1. Aseguramos que normalizedId existe y reemplazamos la consulta
# Buscamos la línea donde se hace la consulta a legacy_import y cambiamos historyId por normalizedId
sed -i '' 's/where("historyId", "==", historyId)/where("historyId", "==", normalizedId)/g' $FILE
sed -i '' 's/where("idH", "==", historyId)/where("idH", "==", normalizedId)/g' $FILE

echo "✅ Consulta actualizada para usar normalizedId."
