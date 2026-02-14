#!/bin/zsh
set -euo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

ROOT="$(pwd -P)"

if [[ ! -d "$ROOT/build/ios/archive" ]]; then
  echo "❌ No existe $ROOT/build/ios/archive"
  exit 1
fi

# Encuentra el .xcarchive más reciente (macOS stat -f)
ARCHIVE="$(
  find "$ROOT/build/ios/archive" -maxdepth 1 -type d -name "*.xcarchive" -print0 \
  | xargs -0 stat -f "%m %N" 2>/dev/null \
  | sort -nr \
  | head -n 1 \
  | cut -d' ' -f2-
)"

if [[ -z "${ARCHIVE:-}" || ! -d "$ARCHIVE" ]]; then
  echo "❌ No encuentro ningún .xcarchive en build/ios/archive/"
  echo "Contenido actual:"
  ls -la "$ROOT/build/ios/archive" || true
  exit 1
fi

DATE_DIR="$(date +%Y-%m-%d)"
DEST_DIR="$HOME/Library/Developer/Xcode/Archives/$DATE_DIR"
mkdir -p "$DEST_DIR"

DEST="$DEST_DIR/$(basename "$ARCHIVE")"

echo "▶️ Archive origen: $ARCHIVE"
echo "▶️ Copiando a:     $DEST"

rm -rf "$DEST" || true
cp -R "$ARCHIVE" "$DEST"

echo "✅ Copiado. Abriendo en Xcode…"
open -a Xcode "$DEST"

echo ""
echo "👉 Ahora ve a: Xcode > Window > Organizer > Archives"
echo "   Si no aparece, cierra y reabre Xcode para forzar el indexado."
