#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$BUILD_DIR/MDore.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SOURCE_DIR="$ROOT_DIR/Sources/MDore"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$DIST_DIR"

SOURCES=("$SOURCE_DIR"/*.swift)
FRAMEWORKS=(-framework SwiftUI -framework AppKit -framework WebKit -framework UniformTypeIdentifiers)

build_arch() {
  local arch="$1"
  swiftc -parse-as-library -O \
    -target "${arch}-apple-macos14.0" \
    -sdk "$SDK_PATH" \
    "${FRAMEWORKS[@]}" \
    "${SOURCES[@]}" \
    -o "$BUILD_DIR/MDore-$arch"
}

build_arch arm64
build_arch x86_64
lipo -create "$BUILD_DIR/MDore-arm64" "$BUILD_DIR/MDore-x86_64" -output "$MACOS_DIR/MDore"

cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Resources/MDore.icns" "$RESOURCES_DIR/MDore.icns"

codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"
plutil -lint "$CONTENTS_DIR/Info.plist"

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$DIST_DIR/MDore-macOS.zip"

DMG_ROOT="$BUILD_DIR/dmg-root"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/MDore.app"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create -quiet -volname "MDore" -srcfolder "$DMG_ROOT" -ov -format UDZO "$DIST_DIR/MDore-macOS.dmg"

echo "Built:"
ls -lh "$DIST_DIR/MDore-macOS.zip" "$DIST_DIR/MDore-macOS.dmg"
