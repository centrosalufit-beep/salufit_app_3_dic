#!/bin/zsh

echo "🔎 Auditando formato de IDs en legacy_import..."
echo "--------------------------------------------------"

# Este script asume que tienes firebase-tools configurado
# Intentamos obtener una muestra de la colección
firebase firestore:get legacy_import --limit 5 --project salufitnewapp > sample_data.json

if [ -s sample_data.json ]; then
    echo "✅ Datos recuperados. Analizando campos clave..."
    # Buscamos campos que parezcan números de historia
    grep -E "historyId|idH|numero" sample_data.json | head -n 10
else
    echo "⚠️ No se pudieron obtener datos directamente. Por favor, revisa la consola de Firebase."
    echo "💡 TIP: Asegúrate de que en legacy_import el campo se llame 'historyId' y tenga 6 cifras."
fi
echo "--------------------------------------------------"
rm sample_data.json
