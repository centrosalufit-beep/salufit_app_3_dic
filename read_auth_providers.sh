#!/bin/zsh

FILE="lib/features/auth/providers/auth_providers.dart"

if [ -f "$FILE" ]; then
    echo "📄 Leyendo estructura de providers en: $FILE"
    echo "--------------------------------------------------"
    cat "$FILE"
    echo "--------------------------------------------------"
else
    echo "❌ No se encontró el archivo en la ruta especificada."
fi
