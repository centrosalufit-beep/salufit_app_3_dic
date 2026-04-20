#!/bin/sh

# ====================================================================
# Xcode Cloud post-clone script para Salufit (Flutter + Firebase)
# ====================================================================
# Xcode Cloud clona el repo en una máquina Apple limpia, sin Flutter,
# y ejecuta `xcodebuild` directamente. Sin este script, no puede
# generar `Flutter/Generated.xcconfig` ni los xcfilelist de Pods.
#
# Este script se ejecuta automáticamente ANTES del build.
# Documentación oficial: https://docs.flutter.dev/deployment/cd#xcode-cloud
# ====================================================================

set -e  # Aborta si cualquier comando falla

echo "🍎 Xcode Cloud — Preparando entorno Flutter..."

# Ir a la raíz del repo (un nivel por encima de ios/)
cd $CI_PRIMARY_REPOSITORY_PATH

# Instalar Flutter en la máquina efímera de Xcode Cloud
echo "📦 Clonando Flutter stable..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "🔍 Verificando Flutter..."
flutter --version

echo "🧹 flutter precache para iOS..."
flutter precache --ios

echo "📥 flutter pub get..."
flutter pub get

# Volver al directorio ios y ejecutar pod install
echo "📱 pod install..."
cd ios
pod install --repo-update

echo "✅ ci_post_clone.sh completado correctamente."
