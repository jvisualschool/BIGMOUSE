#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP="$PWD/dist/BigMouse.app"
if [ -L "$PWD/dist" ] || [ -L "$APP" ] || [ ! -d "$APP" ]; then
  printf 'Build a regular dist/BigMouse.app with bash build.sh first.\n' >&2
  exit 1
fi
if [ -n "$(find "$APP" -type l -print -quit)" ]; then
  printf 'Refusing symlinks inside the release bundle.\n' >&2
  exit 1
fi
# Explicit files only: fail if Finder metadata, credentials, or stale resources appear.
while IFS= read -r entry; do
  relative="${entry#"$APP"/}"
  case "$relative" in
    Contents/Info.plist|Contents/MacOS/BigMouse|Contents/_CodeSignature/CodeResources|\
    Contents/Resources/AppIcon.icns|Contents/Resources/Lucide/LICENSE|\
    Contents/Resources/Lucide/circle-dot.png|Contents/Resources/Lucide/flashlight.png|\
    Contents/Resources/Lucide/keyboard.png|Contents/Resources/Lucide/sparkles.png|\
    Contents/Resources/Lucide/zoom-in.png|Contents/Resources/en.lproj/Localizable.strings|\
    Contents/Resources/ko.lproj/Localizable.strings) ;;
    *) printf 'Unexpected release file: %s\n' "$relative" >&2; exit 1 ;;
  esac
done < <(find "$APP" -type f -print)

codesign --verify --strict "$APP"
plutil -lint "$APP/Contents/Info.plist" \
  "$APP/Contents/Resources/en.lproj/Localizable.strings" \
  "$APP/Contents/Resources/ko.lproj/Localizable.strings"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || { printf 'Invalid release version.\n' >&2; exit 1; }
ARCHITECTURES="$(lipo -archs "$APP/Contents/MacOS/BigMouse")"
case "$ARCHITECTURES" in
  arm64|x86_64) ARCH="$ARCHITECTURES" ;;
  'arm64 x86_64'|'x86_64 arm64') ARCH=universal ;;
  *) printf 'Unexpected architecture: %s\n' "$ARCHITECTURES" >&2; exit 1 ;;
esac
RELEASE_DIR="$PWD/dist/releases/v$VERSION"
if [ -L "$PWD/dist/releases" ] || [ -L "$RELEASE_DIR" ]; then
  printf 'Refusing a symlinked release destination.\n' >&2
  exit 1
fi
mkdir -p "$RELEASE_DIR"
NAME="BigMouse-$VERSION-macos-$ARCH.zip"
if [ -e "$RELEASE_DIR/$NAME" ] || [ -e "$RELEASE_DIR/$NAME.sha256" ]; then
  printf 'Release already exists; move the prior ZIP and checksum before repackaging.\n' >&2
  exit 1
fi
STAGING_DIR="$(mktemp -d "$RELEASE_DIR/.package.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
ditto -c -k --keepParent "$APP" "$STAGING_DIR/$NAME"
(
  cd "$STAGING_DIR"
  shasum -a 256 "$NAME" > "$NAME.sha256"
)
mv "$STAGING_DIR/$NAME" "$STAGING_DIR/$NAME.sha256" "$RELEASE_DIR/"
printf 'Packaged: %s\n' "$RELEASE_DIR/$NAME"
printf 'This verifies bundle integrity, not Developer ID signing or notarization.\n'
