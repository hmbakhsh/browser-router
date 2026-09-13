#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="Browser Router.app"
APP="$ROOT/dist/$APP_NAME"

cd "$ROOT"
BIN_DIR=$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)
swift build -c release --arch arm64 --arch x86_64

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/BrowserRouter" "$APP/Contents/MacOS/BrowserRouter"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"
swift "$ROOT/scripts/generate-icon.swift" "$ICONSET/icon_512x512@2x.png"
for spec in "16:16x16" "32:16x16@2x" "32:32x32" "64:32x32@2x" "128:128x128" "256:128x128@2x" "256:256x256" "512:256x256@2x" "512:512x512"; do
  pixels=${spec%%:*}
  name=${spec#*:}
  sips -z "$pixels" "$pixels" "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_$name.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"

echo "$APP"
