#!/bin/zsh

FILE="lib/features/auth/services/auth_service.dart"

if [ -f "$FILE" ]; then
    echo "📄 Analizando lógica interna en: $FILE"
    echo "--------------------------------------------------"
    cat "$FILE"
    echo "--------------------------------------------------"
else
    echo "❌ No se encontró el archivo AuthService. ¿Podrías confirmar si la ruta es correcta?"
fi
