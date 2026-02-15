#!/bin/zsh

echo "🕵️ Auditando tipos de datos reales en Firestore..."
echo "--------------------------------------------------"

# 1. Inspeccionar un usuario real
echo "👤 Muestra de la colección 'users':"
firebase firestore:get users --limit 1 --project salufitnewapp > user_audit.json
if [ -s user_audit.json ]; then
    # Buscamos el IDH y tratamos de ver si es string o number
    cat user_audit.json | grep -E "historyId|idH|numero|rol|email" | head -n 10
else
    echo "⚠️ No se pudo leer la colección 'users'."
fi

echo "\n--------------------------------------------------"
# 2. Inspeccionar un registro de importación
echo "📂 Muestra de la colección 'legacy_import':"
firebase firestore:get legacy_import --limit 1 --project salufitnewapp > legacy_audit.json
if [ -s legacy_audit.json ]; then
    cat legacy_audit.json | grep -E "historyId|idH|numero|email" | head -n 10
else
    echo "⚠️ No se pudo leer la colección 'legacy_import'."
fi

echo "--------------------------------------------------"
echo "💡 REVISA LA SALIDA:"
echo "- Si ves '\"1\"', es un String (Correcto para nuestro pad)."
echo "- Si ves '1', es un Number (Tendremos que ajustar la función)."
rm user_audit.json legacy_audit.json
