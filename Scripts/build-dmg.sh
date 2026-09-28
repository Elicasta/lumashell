#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

rm -rf dist .build/lumashell-universal
mkdir -p dist .build/lumashell-universal

echo "Building arm64..."
swift build -c release --arch arm64
ARM_DIR="$(swift build -c release --arch arm64 --show-bin-path)"
cp "$ARM_DIR/LumaShell" .build/lumashell-universal/LumaShell-arm64

echo "Building x86_64..."
swift build -c release --arch x86_64
INTEL_DIR="$(swift build -c release --arch x86_64 --show-bin-path)"
cp "$INTEL_DIR/LumaShell" .build/lumashell-universal/LumaShell-x86_64

echo "Creating universal binary..."
lipo -create   .build/lumashell-universal/LumaShell-arm64   .build/lumashell-universal/LumaShell-x86_64   -output .build/lumashell-universal/LumaShell

lipo -info .build/lumashell-universal/LumaShell

APP="$ROOT/dist/LumaShell.app"
CONTENTS="$APP/Contents"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

cp .build/lumashell-universal/LumaShell "$CONTENTS/MacOS/LumaShell"
cp "$ROOT/BundleResources/Info.plist" "$CONTENTS/Info.plist"
chmod +x "$CONTENTS/MacOS/LumaShell"
plutil -lint "$CONTENTS/Info.plist"

codesign --force --deep --sign - "$APP"

STAGE="$ROOT/dist/dmg-stage"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/LumaShell.app"
ln -s /Applications "$STAGE/Applications"

hdiutil create   -volname "LumaShell"   -srcfolder "$STAGE"   -ov   -format UDZO   "$ROOT/dist/LumaShell.dmg"

rm -rf "$STAGE"

echo "Built: $ROOT/dist/LumaShell.dmg"
