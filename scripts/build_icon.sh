#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONSET="$(mktemp -d /tmp/mdore-icon.XXXXXX)/MDore.iconset"
SOURCE_PNG="${ICONSET%/MDore.iconset}/MDore-1024.png"
mkdir -p "$ICONSET"

swift "$ROOT_DIR/scripts/create_app_icon.swift" \
  "$ROOT_DIR/Resources/Brand/logo.svg" \
  "$SOURCE_PNG"

for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$SOURCE_PNG" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  doubled=$((size * 2))
  sips -z "$doubled" "$doubled" "$SOURCE_PNG" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o "$ROOT_DIR/Resources/MDore.icns"
echo "Updated $ROOT_DIR/Resources/MDore.icns"
