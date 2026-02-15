#!/bin/zsh

echo "🔍 Buscando el archivo de la pantalla de activación..."
# Buscamos el archivo que contiene el texto del botón de la captura
FILE_PATH=$(grep -rl "VERIFICAR MI IDENTIDAD" lib/ | head -n 1)

if [ -z "$FILE_PATH" ]; then
    echo "❌ No se encontró el archivo. Por favor, asegúrate de estar en la raíz del proyecto Flutter."
    exit 1
fi

echo "✅ Archivo detectado en: $FILE_PATH"
echo "--------------------------------------------------"
echo "CONTENIDO DEL ARCHIVO:"
echo "--------------------------------------------------"
cat "$FILE_PATH"
echo "--------------------------------------------------"
