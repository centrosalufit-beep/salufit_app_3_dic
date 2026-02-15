#!/bin/zsh

# 1. Asegurar que estamos en una rama (main o master)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "🚀 Iniciando respaldo en la rama: $BRANCH"

# 2. Añadir todos los archivos nuevos y modificados
git add .

# 3. Crear el commit de seguridad
# Usamos un mensaje descriptivo para el historial
git commit -m "COPIA DE SEGURIDAD - Activación, Cloud Functions y Lints OK (Feb 2026)"

# 4. Crear el Tag (Etiqueta de búsqueda rápida)
# Si el tag ya existe, lo borramos localmente para actualizarlo
git tag -d COPIA_DE_SEGURIDAD 2>/dev/null
git tag -a COPIA_DE_SEGURIDAD -m "Punto de restauración estable: Flujo de activación validado."

# 5. Push al repositorio remoto (incluyendo el tag)
echo "📤 Subiendo cambios a GitHub..."
git push origin $BRANCH
git push origin --tags --force

echo "--------------------------------------------------"
echo "✅ RESPALDO COMPLETADO EXITOSAMENTE"
echo "📌 Busca 'COPIA_DE_SEGURIDAD' en la sección Tags/Releases de GitHub."
echo "--------------------------------------------------"
