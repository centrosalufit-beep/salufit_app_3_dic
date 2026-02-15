#!/bin/zsh

FILE="src/index.ts" # O el archivo donde definiste checkAccountStatus

echo "⚙️ Reforzando lógica de normalización en la Cloud Function..."

# Usamos sed para asegurar que la función normalice el historyId
# Añadimos: const normalizedId = historyId.toString().padStart(6, '0');
# Y cambiamos la búsqueda para que use normalizedId
sed -i '' 's/const { email, historyId } = data;/const { email, historyId } = data; const normalizedId = historyId.toString().trim().padStart(6, "0");/' $FILE

echo "✅ Lógica reforzada. Ahora '1' y '000001' son idénticos para el servidor."
