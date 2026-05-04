#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════╗
# ║  Salufit — Comprobaciones previas al build .ipa en macOS           ║
# ║                                                                    ║
# ║  Verifica TODOS los requisitos (Xcode, CocoaPods, Flutter, Apple   ║
# ║  Developer cert, GoogleService-Info.plist, rama correcta) y SI     ║
# ║  todo está OK ejecuta automáticamente la preparación del entorno   ║
# ║  (pub get, pod install, build_runner, analyze).                    ║
# ║                                                                    ║
# ║  Tras ejecutar este script con éxito, ya puedes lanzar:            ║
# ║      flutter build ipa --release                                   ║
# ║                                                                    ║
# ║  Uso (desde la raíz del proyecto en el Mac):                       ║
# ║      bash scripts/check_mac_ios.sh                                 ║
# ╚═══════════════════════════════════════════════════════════════════╝

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ok()    { echo -e "${GREEN}✅${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠️ ${NC} $1"; }
fail()  { echo -e "${RED}❌${NC} $1"; }
info()  { echo -e "${BLUE}ℹ️ ${NC} $1"; }
title() { echo -e "\n${BOLD}═══ $1 ═══${NC}"; }

ERRORS=0
record_error() { ERRORS=$((ERRORS + 1)); }

# ──────────────────────────────────────────────────────────────────
title "0. Plataforma"
# ──────────────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "Este script SOLO funciona en macOS. Estás en $(uname -s)."
  exit 1
fi
ok "macOS detectado ($(sw_vers -productVersion))"

# ──────────────────────────────────────────────────────────────────
title "1. Xcode + Command Line Tools"
# ──────────────────────────────────────────────────────────────────
if command -v xcodebuild >/dev/null 2>&1; then
  XCODE_VER=$(xcodebuild -version 2>/dev/null | head -1)
  ok "Xcode instalado: $XCODE_VER"

  # Comprobar licencia aceptada
  if xcodebuild -checkFirstLaunchStatus 2>/dev/null; then
    ok "Licencia Xcode aceptada"
  else
    warn "Licencia Xcode no aceptada — ejecuta: sudo xcodebuild -license accept"
    record_error
  fi

  # Command Line Tools path
  if xcode-select -p >/dev/null 2>&1; then
    ok "Command Line Tools en: $(xcode-select -p)"
  else
    fail "Command Line Tools no configuradas. Ejecuta: sudo xcode-select --install"
    record_error
  fi
else
  fail "Xcode no instalado. Bájalo de la App Store."
  record_error
fi

# ──────────────────────────────────────────────────────────────────
title "2. CocoaPods"
# ──────────────────────────────────────────────────────────────────
if command -v pod >/dev/null 2>&1; then
  ok "CocoaPods instalado: $(pod --version)"
else
  fail "CocoaPods NO instalado. Ejecuta: brew install cocoapods"
  record_error
fi

# ──────────────────────────────────────────────────────────────────
title "3. Flutter"
# ──────────────────────────────────────────────────────────────────
if command -v flutter >/dev/null 2>&1; then
  FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')
  ok "Flutter instalado: $FLUTTER_VER"
  REQUIRED="3.41.7"
  if [[ "$(printf '%s\n' "$REQUIRED" "$FLUTTER_VER" | sort -V | head -1)" != "$REQUIRED" ]]; then
    warn "Flutter $FLUTTER_VER es anterior al recomendado $REQUIRED. Considera 'flutter upgrade'."
  fi
else
  fail "Flutter NO instalado. Ejecuta: brew install --cask flutter"
  record_error
fi

# ──────────────────────────────────────────────────────────────────
title "4. Cuenta Apple Developer firmada en Xcode"
# ──────────────────────────────────────────────────────────────────
# Buscamos certificados de distribución iOS en el llavero
DIST_CERTS=$(security find-identity -v -p codesigning 2>/dev/null \
  | grep -E "Apple Distribution|iPhone Distribution" || true)
if [[ -n "$DIST_CERTS" ]]; then
  CERT_COUNT=$(echo "$DIST_CERTS" | wc -l | tr -d ' ')
  ok "$CERT_COUNT certificado(s) de distribución iOS encontrado(s) en el Keychain"
  echo "$DIST_CERTS" | sed 's/^/    /'
else
  warn "No hay certificados de distribución iOS en el Keychain."
  warn "Si nunca subiste apps desde este Mac, abre Xcode → Settings → Accounts"
  warn "y firma con tu Apple ID del equipo Salufit."
  record_error
fi

# ──────────────────────────────────────────────────────────────────
title "5. Estado del repo Git"
# ──────────────────────────────────────────────────────────────────
if [[ ! -d ".git" ]]; then
  fail "No estás en la raíz de un repo git. Ejecuta este script desde la raíz del proyecto."
  exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)
EXPECTED_BRANCH="feat/admin-windows-bot"
if [[ "$CURRENT_BRANCH" == "$EXPECTED_BRANCH" ]]; then
  ok "Rama actual: $CURRENT_BRANCH"
else
  warn "Estás en '$CURRENT_BRANCH', se espera '$EXPECTED_BRANCH'"
  read -p "  ¿Cambio a $EXPECTED_BRANCH? [y/N] " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    git fetch origin
    git checkout "$EXPECTED_BRANCH"
    ok "Cambiado a $EXPECTED_BRANCH"
  else
    record_error
  fi
fi

LAST_COMMIT=$(git log --oneline -1)
info "Último commit: $LAST_COMMIT"

# Comprobar si está al día con remote
git fetch origin "$EXPECTED_BRANCH" --quiet 2>/dev/null || true
LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse "origin/$EXPECTED_BRANCH" 2>/dev/null || echo "$LOCAL_HASH")
if [[ "$LOCAL_HASH" == "$REMOTE_HASH" ]]; then
  ok "Sincronizado con origin/$EXPECTED_BRANCH"
else
  warn "Hay commits remotos que no tienes localmente."
  read -p "  ¿Hago git pull? [y/N] " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    git pull --ff-only origin "$EXPECTED_BRANCH"
    ok "Pull completado"
  fi
fi

# ──────────────────────────────────────────────────────────────────
title "6. Versión en pubspec.yaml"
# ──────────────────────────────────────────────────────────────────
VERSION_LINE=$(grep "^version:" pubspec.yaml || echo "")
info "$VERSION_LINE"
if echo "$VERSION_LINE" | grep -q "2.0.9+141"; then
  ok "Versión correcta: 2.0.9+141 (correlacionada con la Play Store)"
else
  warn "La versión NO es 2.0.9+141. Revisa que esté correcta."
fi

# ──────────────────────────────────────────────────────────────────
title "7. GoogleService-Info.plist (Firebase iOS)"
# ──────────────────────────────────────────────────────────────────
PLIST_PATH="ios/Runner/GoogleService-Info.plist"
if [[ -f "$PLIST_PATH" ]]; then
  ok "GoogleService-Info.plist presente en $PLIST_PATH"
  # Verificar que el bundle ID coincide
  PLIST_BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$PLIST_PATH" 2>/dev/null || echo "")
  if [[ "$PLIST_BUNDLE" == "com.salufit.app" ]]; then
    ok "Bundle ID coincide: $PLIST_BUNDLE"
  else
    warn "Bundle ID en plist es '$PLIST_BUNDLE', se espera 'com.salufit.app'"
  fi
else
  fail "GoogleService-Info.plist NO está en $PLIST_PATH"
  echo ""
  echo "    Descárgalo desde:"
  echo "    https://console.firebase.google.com/project/salufitnewapp/settings/general"
  echo "    Sección 'Tus apps' → app iOS → Descargar GoogleService-Info.plist"
  echo ""
  echo "    Luego cópialo al sitio:"
  echo "      cp ~/Downloads/GoogleService-Info.plist $PLIST_PATH"
  echo ""
  record_error
fi

# Asegurar que está en .gitignore
if ! grep -q "GoogleService-Info.plist" .gitignore 2>/dev/null; then
  warn ".gitignore NO excluye GoogleService-Info.plist — añadiendo entrada"
  echo "" >> .gitignore
  echo "# Firebase iOS config — NUNCA subir al repo" >> .gitignore
  echo "ios/Runner/GoogleService-Info.plist" >> .gitignore
  ok "Añadido a .gitignore (recuerda commitear el .gitignore)"
fi

# ──────────────────────────────────────────────────────────────────
title "8. Bundle ID y firma del proyecto Xcode"
# ──────────────────────────────────────────────────────────────────
PBX="ios/Runner.xcodeproj/project.pbxproj"
if [[ -f "$PBX" ]]; then
  if grep -q "PRODUCT_BUNDLE_IDENTIFIER = com.salufit.app;" "$PBX"; then
    ok "Bundle ID en proyecto Xcode: com.salufit.app"
  else
    warn "Bundle ID NO es com.salufit.app. Revisa el target Runner en Xcode."
  fi
fi

# ──────────────────────────────────────────────────────────────────
title "RESUMEN PRE-BUILD"
# ──────────────────────────────────────────────────────────────────
if [[ $ERRORS -gt 0 ]]; then
  echo ""
  fail "Se encontraron $ERRORS problema(s). Resuélvelos antes de seguir."
  echo ""
  exit 1
fi
ok "Todas las comprobaciones pasaron. Procedo a preparar el entorno."

# ──────────────────────────────────────────────────────────────────
title "9. flutter pub get"
# ──────────────────────────────────────────────────────────────────
flutter pub get
ok "Dependencias Dart instaladas"

# ──────────────────────────────────────────────────────────────────
title "10. pod install (CocoaPods)"
# ──────────────────────────────────────────────────────────────────
pushd ios > /dev/null
pod install --repo-update
popd > /dev/null
ok "Pods instalados"

# ──────────────────────────────────────────────────────────────────
title "11. build_runner (genera .freezed/.g.dart)"
# ──────────────────────────────────────────────────────────────────
dart run build_runner build --delete-conflicting-outputs
ok "Archivos generados"

# ──────────────────────────────────────────────────────────────────
title "12. flutter analyze"
# ──────────────────────────────────────────────────────────────────
if flutter analyze; then
  ok "Sin issues"
else
  fail "Hay errores de análisis. NO lances el build hasta arreglarlos."
  exit 1
fi

# ──────────────────────────────────────────────────────────────────
title "🎉 LISTO PARA COMPILAR"
# ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Todo en orden.${NC} Ahora ejecuta:"
echo ""
echo -e "    ${BOLD}flutter build ipa --release${NC}"
echo ""
echo "El .ipa quedará en: build/ios/ipa/salufit_app.ipa"
echo "Súbelo con Transporter (App Store del Mac → arrastrar → Deliver)."
echo ""
echo "Notas de versión sugeridas para App Store Connect (sec. 8 de BUILD_IPA.md):"
cat <<'EOF'

  - Hub de inicio en Windows con tarjetas por feature.
  - Filtro de visibilidad por rol: profesionales solo ven lo que necesitan.
  - Activación funcional en Windows (HTTP fallback a Cloud Functions).
  - Login muestra errores visibles (contraseña errónea, sin red, etc.).
  - Pantalla de error explícita si el perfil no se resuelve.
  - QR walkin con anti-doble-consumo (5 min).
  - Lista de apuntados a clase visible para profesional/admin (mobile).
  - Bot WhatsApp: panel arranca con filtro "Solo activas" por defecto.
  - Tipografía y colores uniformes en pantallas admin.
  - Correcciones varias de UI y rendimiento.

EOF
