#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
DEVELOPMENT=0
case "${1:-}" in
  '') python3 scripts/signing.py check ;;
  --development) DEVELOPMENT=1 ;;
  *) printf 'Usage: bash build.sh [--development]\n' >&2; exit 1 ;;
esac
OUTPUT_APP="$PWD/dist/BigMouse.app"
if [ "$DEVELOPMENT" = 1 ]; then OUTPUT_APP="$PWD/dist/BigMouse Dev.app"; fi
if [ -L "$PWD/dist" ] || [ -L "$OUTPUT_APP" ]; then
  printf 'Refusing a symlinked build destination.\n' >&2
  exit 1
fi
mkdir -p "$PWD/dist" "$PWD/.build/module-cache"
STAGING_DIR="$(mktemp -d "$PWD/.build/staging.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
APP="$STAGING_DIR/BigMouse.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
ICONSET="$PWD/.build/AppIcon.iconset"
mkdir -p "$ICONSET"
for entry in 16x16:16 16x16@2x:32 32x32:32 32x32@2x:64 \
             128x128:128 128x128@2x:256 256x256:256 256x256@2x:512 \
             512x512:512 512x512@2x:1024; do
  icon_name="${entry%:*}"
  icon_pixels="${entry#*:}"
  if [ "$icon_pixels" = 512 ]; then
    cp Resources/AppIcon.png "$ICONSET/icon_${icon_name}.png"
  else
    sips -z "$icon_pixels" "$icon_pixels" Resources/AppIcon.png \
      --out "$ICONSET/icon_${icon_name}.png" >/dev/null
  fi
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
xcrun swiftc -Osize -whole-module-optimization -swift-version 5 \
  -target "$(uname -m)-apple-macosx13.0" \
  -module-cache-path "$PWD/.build/module-cache" \
  -framework AppKit -framework SwiftUI -framework QuartzCore -framework ScreenCaptureKit -framework CoreImage \
  Sources/*.swift -o "$APP/Contents/MacOS/BigMouse"
# Remove debug/local symbol names; retain runtime metadata and dynamic symbols.
xcrun strip -S -x "$APP/Contents/MacOS/BigMouse"
cp Resources/Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources/Lucide"
cp Resources/Lucide/*.png Resources/Lucide/LICENSE "$APP/Contents/Resources/Lucide/"
cp -R Resources/en.lproj Resources/ko.lproj "$APP/Contents/Resources/"
if [ "$DEVELOPMENT" = 1 ]; then
  # A separate identity keeps experimental builds away from release permissions.
  /usr/libexec/PlistBuddy -c 'Set CFBundleIdentifier com.jvisualschool.BigMouse.Development' "$APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set CFBundleDisplayName BigMouse Dev' "$APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set CFBundleName BigMouse Dev' "$APP/Contents/Info.plist"
  codesign --force --sign - "$APP"
  codesign --verify --strict "$APP"
else
  python3 scripts/signing.py sign "$APP"
fi
# Only replace the prior build after compilation, resource copy and signing succeed.
# A clean staging bundle prevents stale files from entering future releases.
if [ -e "$OUTPUT_APP" ]; then mv "$OUTPUT_APP" "$STAGING_DIR/previous.app"; fi
if ! mv "$APP" "$OUTPUT_APP"; then
  if [ -d "$STAGING_DIR/previous.app" ]; then mv "$STAGING_DIR/previous.app" "$OUTPUT_APP"; fi
  exit 1
fi
printf '완료: %s\n' "$OUTPUT_APP"
