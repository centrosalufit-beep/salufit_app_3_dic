#!/bin/zsh
echo "🔍 Extrayendo datos brutos para análisis técnico..."
echo "--------------------------------------------------"

# 1. Ver un usuario de la colección 'users'
echo "👤 DOCUMENTO EN 'users':"
firebase firestore:get users --limit 1 --project salufitnewapp

echo "\n--------------------------------------------------"

# 2. Ver un registro en 'legacy_import'
echo "📂 DOCUMENTO EN 'legacy_import':"
firebase firestore:get legacy_import --limit 1 --project salufitnewapp

echo "--------------------------------------------------"
