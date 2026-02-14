#!/bin/zsh
set -euo pipefail

# Asegura herramientas básicas en macOS aunque el entorno tenga PATH raro
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# =========================
# CONFIG (ajusta si quieres)
# =========================
RUN_FLUTTER_ANALYZE=1
RUN_FLUTTER_TESTS=0
RUN_IOS_PODS=1
RUN_IOS_ARCHIVE=1
RUN_FLUTTER_BUILD_IPA=0   # pon 1 si quieres intentar exportar IPA

# =========================
# HELPERS
# =========================
ts() { /bin/date +"%Y%m%d_%H%M%S"; }
iso_now() { /bin/date -u +"%Y-%m-%dT%H:%M:%SZ"; }
say() { print -r -- "$*"; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    say "❌ Falta el comando: $1"
    exit 1
  fi
}

append() { print -r -- "$*" >> "$REPORT"; }

append_cmd() {
  local title="$1"; shift
  append ""
  append "===================="
  append "CMD: $title"
  append "===================="
  {
    "$@"
  } >> "$REPORT" 2>&1 || {
    append "⚠️  Comando falló: $title"
    return 0
  }
}

redact_stream() {
  /usr/bin/sed -E \
    -e 's/(apiKey|API_KEY|client_secret|CLIENT_SECRET|secret|SECRET|private_key|PRIVATE_KEY|token|TOKEN|password|PASSWORD)[^=:" ]*([=:" ]+)[^," ]+/\1\2***REDACTED***/g' \
    -e 's/-----BEGIN [A-Z ]+-----/-----BEGIN ***REDACTED***-----/g' \
    -e 's/-----END [A-Z ]+-----/-----END ***REDACTED***-----/g'
}

append_file() {
  local path="$1"
  append ""
  append "===================="
  append "FILE: $path"
  append "===================="
  if [[ -f "$path" ]]; then
    local bytes
    bytes=$(/usr/bin/wc -c < "$path" | /usr/bin/tr -d ' ')
    append "Size(bytes): $bytes"
    if [[ "$bytes" -gt 800000 ]]; then
      append "⚠️  Archivo muy grande. Volcando solo primeras 400 líneas."
      (head -n 400 "$path" | redact_stream) >> "$REPORT"
      append ""
      append "…(truncado)…"
    else
      (cat "$path" | redact_stream) >> "$REPORT"
    fi
  else
    append "❌ No existe."
  fi
}

hash_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    shasum -a 256 "$path" | awk '{print $1}'
  else
    echo "MISSING"
  fi
}

# =========================
# PRECHECKS
# =========================
say "▶️  Running audit script from: $(pwd -P)"
if [[ ! -f "pubspec.yaml" ]]; then
  say "❌ No encuentro pubspec.yaml. Ejecuta esto en la raíz del proyecto Flutter."
  exit 1
fi

require_cmd git
require_cmd flutter
require_cmd dart

if [[ "$RUN_IOS_ARCHIVE" -eq 1 || "$RUN_FLUTTER_BUILD_IPA" -eq 1 ]]; then
  require_cmd xcodebuild
fi

# =========================
# OUTPUT DIRS
# =========================
OUT="audit_out_$(ts)"
mkdir -p "$OUT/logs"
REPORT="$OUT/audit_report.txt"
: > "$REPORT"

append "SALUFIT APP AUDIT REPORT"
append "Generated(UTC): $(iso_now)"
append "Repo root: $(pwd -P)"
append ""

# =========================
# ENV / TOOLING
# =========================
append_cmd "macOS version" sw_vers
append_cmd "CPU/arch" uname -a
append_cmd "Xcode version" xcodebuild -version || true
append_cmd "xcode-select" xcode-select -p || true
append_cmd "Flutter doctor -v" flutter doctor -v
append_cmd "Flutter version" flutter --version
append_cmd "Dart version" dart --version
append_cmd "CocoaPods version" pod --version || true
append_cmd "Ruby version" ruby -v || true
append_cmd "Java version" java -version || true

# =========================
# GIT CONTEXT
# =========================
append_cmd "Git status" git status
append_cmd "Git branch" git branch --show-current
append_cmd "Git commit" git rev-parse HEAD
append_cmd "Git remotes" git remote -v
append_cmd "Git short log (last 20)" git --no-pager log -20 --oneline

git diff > "$OUT/uncommitted.diff" || true
git diff --staged > "$OUT/staged.diff" || true
append "Saved diffs:"
append " - $OUT/uncommitted.diff"
append " - $OUT/staged.diff"

# =========================
# TREE (sin basura)
# =========================
append ""
append "===================="
append "PROJECT TREE (depth 4, excluding build artifacts)"
append "===================="
find . -maxdepth 4 \
  -type d \( -name .git -o -name build -o -name .dart_tool -o -name .idea -o -name .vscode -o -name Pods -o -name .symlinks -o -name node_modules -o -name .gradle \) -prune -false \
  -o -type f -print \
  | sed 's|^\./||' \
  | sort \
  >> "$REPORT"

# =========================
# DEPENDENCIES / ANALYSIS
# =========================
append_cmd "Flutter pub get" flutter pub get
append_cmd "Dart pub deps (compact)" dart pub deps --style=compact

if [[ "$RUN_FLUTTER_ANALYZE" -eq 1 ]]; then
  append_cmd "Flutter analyze" flutter analyze
fi

if [[ "$RUN_FLUTTER_TESTS" -eq 1 ]]; then
  append_cmd "Flutter test" flutter test
fi

# =========================
# KEY FILE SNAPSHOTS
# =========================
append ""
append "===================="
append "KEY FILE SNAPSHOTS"
append "===================="

append_file "pubspec.yaml"
append_file "pubspec.lock"
append_file "analysis_options.yaml"

append_file "firebase.json"
append_file ".firebaserc"
append_file "firestore.rules"
append_file "storage.rules"

append_file "functions/package.json"
append_file "functions/tsconfig.json"
append_file "functions/src/index.ts"
append_file "functions/src/main.ts"

append_file "android/build.gradle"
append_file "android/settings.gradle"
append_file "android/gradle.properties"
append_file "android/gradle/wrapper/gradle-wrapper.properties"
append_file "android/app/build.gradle"
append_file "android/app/src/main/AndroidManifest.xml"

append_file "ios/Podfile"
append_file "ios/Podfile.lock"
append_file "ios/Runner/Info.plist"
append_file "ios/Runner/Runner.entitlements"
append_file "ios/Runner.xcodeproj/project.pbxproj"

append ""
append "===================="
append "GOOGLESERVICE FILE HASHES (no content dumped)"
append "===================="
append "android/app/google-services.json sha256: $(hash_file android/app/google-services.json)"
append "ios/Runner/GoogleService-Info.plist sha256: $(hash_file ios/Runner/GoogleService-Info.plist)"

append_file "ios/fastlane/Fastfile"
append_file "ios/fastlane/Appfile"

# =========================
# CLEAN + PODS
# =========================
append ""
append "===================="
append "CLEAN / PODS"
append "===================="

append_cmd "flutter clean" flutter clean
append_cmd "flutter pub get (post-clean)" flutter pub get

if [[ "$RUN_IOS_PODS" -eq 1 && -d "ios" ]]; then
  if command -v pod >/dev/null 2>&1; then
    append_cmd "pod install" sh -c 'cd ios && pod install'
  else
    append "⚠️ CocoaPods no está instalado (pod)."
  fi
fi

# =========================
# iOS ARCHIVE (Product -> Archive)
# =========================
append ""
append "===================="
append "iOS ARCHIVE"
append "===================="

ARCHIVE_PATH="build/ios/archive/Runner_$(ts).xcarchive"
mkdir -p "build/ios/archive"

if [[ "$RUN_IOS_ARCHIVE" -eq 1 ]]; then
  say "📦 Intentando xcodebuild archive…"
  IOS_LOG="$OUT/logs/ios_archive.log"

  set +e
  xcodebuild \
    -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    | tee "$IOS_LOG"
  XCB_STATUS=${pipestatus[1]}
  set -e

  append "Archive log saved: $IOS_LOG"
  append "Archive output path: $ARCHIVE_PATH"
  if [[ "$XCB_STATUS" -ne 0 ]]; then
    append "❌ xcodebuild archive FAILED (exit $XCB_STATUS)."
    say "❌ Archive falló. Revisa: $IOS_LOG"
  else
    append "✅ xcodebuild archive OK."
    say "✅ Archive OK: $ARCHIVE_PATH"
    say "👉 Abre Xcode > Window > Organizer para subir a App Store Connect."
  fi
fi

# =========================
# OPTIONAL: flutter build ipa
# =========================
if [[ "$RUN_FLUTTER_BUILD_IPA" -eq 1 ]]; then
  IPA_LOG="$OUT/logs/flutter_build_ipa.log"
  say "📦 Intentando flutter build ipa…"
  set +e
  flutter build ipa --release --verbose | tee "$IPA_LOG"
  IPA_STATUS=${pipestatus[1]}
  set -e

  append "flutter build ipa log saved: $IPA_LOG"
  if [[ "$IPA_STATUS" -ne 0 ]]; then
    append "❌ flutter build ipa FAILED (exit $IPA_STATUS)."
    say "❌ flutter build ipa falló. Revisa: $IPA_LOG"
  else
    append "✅ flutter build ipa OK."
    say "✅ flutter build ipa OK (mira build/ios/ipa/ si tu export lo generó)"
  fi
fi

say ""
say "✅ Auditoría generada en: $OUT"
say "   - Report: $REPORT"
say "   - Logs:   $OUT/logs/"
say "   - Diffs:  $OUT/uncommitted.diff y $OUT/staged.diff"
say ""
say "📤 Para que yo lo audite: adjunta:"
say "   1) $REPORT"
say "   2) $OUT/logs/ios_archive.log"
say "   3) $OUT/uncommitted.diff (si hay cambios)"
