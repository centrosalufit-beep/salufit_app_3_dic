#!/bin/zsh
set -euo pipefail

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Falta comando: $1"; exit 1; }; }

need zsh; need git; need flutter; need dart; need sed; need grep; need rm; need date; need tee

if [[ ! -f "pubspec.yaml" ]]; then
  echo "❌ Ejecuta esto en la raíz del proyecto (donde está pubspec.yaml)."
  exit 1
fi

TS=$(date +"%Y%m%d_%H%M%S")
OUT="one_shot_ios_fix_$TS"
mkdir -p "$OUT/logs"

echo "▶️ Repo: $(pwd -P)"
echo "▶️ HOME: $HOME"
echo "▶️ PATH: $PATH"

echo "1) Limpieza DerivedData…"
rm -rf ~/Library/Developer/Xcode/DerivedData || true

echo "2) (Opcional) reparar pub-cache + deps…"
rm -rf ~/.pub-cache/hosted/pub.dev/wakelock_plus-1.3.3 || true
flutter pub cache repair | tee "$OUT/logs/pub_cache_repair.log" || true

echo "3) Parche SSOT: mobile_scanner -> ^7.1.4 (resuelve GoogleDataTransport)…"
if grep -qE '^[[:space:]]*mobile_scanner:' pubspec.yaml; then
  sed -i '' -E 's/^[[:space:]]*mobile_scanner:.*$/  mobile_scanner: ^7.1.4/' pubspec.yaml
else
  if grep -qE '^dependencies:' pubspec.yaml; then
    sed -i '' -E '/^dependencies:/a\
  mobile_scanner: ^7.1.4
' pubspec.yaml
  else
    echo "❌ No encuentro bloque 'dependencies:' en pubspec.yaml."
    exit 1
  fi
fi

echo "4) Limpieza Flutter…"
flutter clean | tee "$OUT/logs/flutter_clean.log"

echo "5) Regenerar configs iOS (esto crea ios/Flutter/Generated.xcconfig)…"
flutter pub get | tee "$OUT/logs/pub_get_after_clean.log"
# Fuerza generación de xcconfig sin compilar binarios
flutter build ios --config-only | tee "$OUT/logs/flutter_build_ios_config_only.log"

if [[ ! -f "ios/Flutter/Generated.xcconfig" ]]; then
  echo "❌ Sigue faltando ios/Flutter/Generated.xcconfig tras --config-only."
  echo "   Revisa: $OUT/logs/flutter_build_ios_config_only.log"
  exit 1
fi

echo "6) Reinstalar Pods desde cero…"
need pod
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks || true

pushd ios >/dev/null
pod deintegrate | tee "../$OUT/logs/pod_deintegrate.log" || true
pod repo update | tee "../$OUT/logs/pod_repo_update.log" || true
pod install --repo-update | tee "../$OUT/logs/pod_install.log"
popd >/dev/null

echo "7) Archive (Product > Archive) vía xcodebuild…"
need xcodebuild
ARCHIVE_PATH="build/ios/archive/Runner_${TS}.xcarchive"
mkdir -p "build/ios/archive"

set +e
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  | tee "$OUT/logs/xcodebuild_archive.log"
STATUS=${pipestatus[1]}
set -e

echo ""
echo "===================="
echo "RESULTADOS"
echo "===================="
echo "Logs: $OUT/logs/"
echo "Archive: $ARCHIVE_PATH"
echo "Exit: $STATUS"

if [[ "$STATUS" -ne 0 ]]; then
  echo "❌ Archive falló."
  echo "👉 Pega aquí:"
  echo "   tail -n 80 $OUT/logs/xcodebuild_archive.log"
  exit 1
else
  echo "✅ Archive OK."
  echo "👉 Xcode > Window > Organizer para subir a App Store Connect."
fi
