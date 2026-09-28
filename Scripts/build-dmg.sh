#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

rm -rf dist
mkdir -p dist

echo "Running tests..."
swift test

echo "Building universal release binary..."
swift build -c release --arch arm64 --arch x86_64
BIN_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"

APP="$ROOT/dist/LumaShell.app"
CONTENTS="$APP/Contents"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

cp "$BIN_DIR/LumaShell" "$CONTENTS/MacOS/LumaShell"
cp "$ROOT/BundleResources/Info.plist" "$CONTENTS/Info.plist"
chmod +x "$CONTENTS/MacOS/LumaShell"

codesign --force --deep --sign - "$APP"

STAGE="$ROOT/dist/dmg-stage"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/LumaShell.app"
ln -s /Applications "$STAGE/Applications"

hdiutil create   -volname "LumaShell"   -srcfolder "$STAGE"   -ov   -format UDZO   "$ROOT/dist/LumaShell.dmg"

rm -rf "$STAGE"

echo "Built: $ROOT/dist/LumaShell.dmg"
