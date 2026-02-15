#!/bin/zsh

FILE="lib/features/auth/services/auth_service.dart"

echo "🧐 Verificando la inyección de código en AuthService..."
echo "--------------------------------------------------"
# Buscamos el método y mostramos las líneas siguientes
grep -A 8 "sendPasswordResetEmail" "$FILE"
echo "--------------------------------------------------"
