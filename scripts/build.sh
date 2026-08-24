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
MOUNT_POINT=""

cleanup() {
  if [[ -n "$MOUNT_POINT" && -d "$MOUNT_POINT" ]]; then hdiutil detach -quiet "$MOUNT_POINT" || true; fi
}
trap cleanup EXIT

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
cp -R "$ROOT_DIR/Resources/Vendor" "$RESOURCES_DIR/Vendor"
cp -R "$ROOT_DIR/Resources/Brand" "$RESOURCES_DIR/Brand"

codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"
plutil -lint "$CONTENTS_DIR/Info.plist"

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$DIST_DIR/MDore-macOS.zip"

DMG_ROOT="$BUILD_DIR/dmg-root"
mkdir -p "$DMG_ROOT/.background"
cp -R "$APP_DIR" "$DMG_ROOT/MDore.app"
ln -s /Applications "$DMG_ROOT/Applications"
cp "$ROOT_DIR/Resources/INSTALL.txt" "$DMG_ROOT/INSTALL.txt"
cp "$ROOT_DIR/Resources/DMG/.DS_Store" "$DMG_ROOT/.DS_Store"

swift "$ROOT_DIR/scripts/create_dmg_background.swift" \
  "$DMG_ROOT/.background/background.png" \
  "$ROOT_DIR/Resources/DMG/installer-texture.png"

RW_DMG="$BUILD_DIR/MDore-rw.dmg"
hdiutil create -quiet -volname "MDore Installer" -srcfolder "$DMG_ROOT" -ov -format UDRW "$RW_DMG"
MOUNT_POINT="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG" | tail -1 | sed -E 's|^.*(/Volumes/)|/Volumes/|')"

osascript <<'APPLESCRIPT' || true
tell application "Finder"
  tell disk "MDore Installer"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {120, 120, 840, 560}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 96
    set text size of viewOptions to 13
    set background picture of viewOptions to file ".background:background.png"
    set position of item "MDore.app" to {180, 225}
    set position of item "Applications" to {540, 225}
    set position of item "INSTALL.txt" to {360, 315}
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach -quiet "$MOUNT_POINT"
MOUNT_POINT=""
hdiutil convert -quiet "$RW_DMG" -format UDZO -o "$DIST_DIR/MDore-macOS.dmg"

echo "Built:"
ls -lh "$DIST_DIR/MDore-macOS.zip" "$DIST_DIR/MDore-macOS.dmg"
