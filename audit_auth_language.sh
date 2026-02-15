#!/bin/zsh

echo "🔍 Localizando el servicio de autenticación..."
# Buscamos donde se define el provider del servicio de auth
AUTH_FILE=$(grep -rl "authServiceProvider =" lib/ | head -n 1)

if [ -z "$AUTH_FILE" ]; then
    echo "❌ No se encontró el archivo del provider. Buscando por implementación..."
    AUTH_FILE=$(grep -rl "sendPasswordResetEmail" lib/ | grep -v "activation_screen" | head -n 1)
fi

if [ -z "$AUTH_FILE" ]; then
    echo "❌ No se pudo localizar el servicio. Por favor, confirma la ruta."
    exit 1
fi

echo "✅ Servicio detectado en: $AUTH_FILE"
echo "--------------------------------------------------"
echo "LOGICA DE ENVÍO DETECTADA:"
echo "--------------------------------------------------"
# Mostramos el método de reset y las primeras líneas para ver el constructor
grep -A 15 "sendPasswordResetEmail" "$AUTH_FILE"
echo "--------------------------------------------------"
