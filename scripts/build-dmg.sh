#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/CodexNotifier.xcodeproj"
SCHEME="CodexNotifier"
CONFIGURATION="Release"
DERIVED_DATA_PATH="$ROOT_DIR/build"
PRODUCTS_DIR="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION"
APP_NAME="CodexNotifier.app"
APP_PATH="$PRODUCTS_DIR/$APP_NAME"
DIST_DIR="$ROOT_DIR/dist"
DMG_NAME="${DMG_NAME:-CodexNotifier}"
DMG_PATH="$DIST_DIR/$DMG_NAME.dmg"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build \
  CODE_SIGNING_ALLOWED=NO

if [[ -n "${MACOS_SIGN_IDENTITY:-}" ]]; then
  if [[ -d "$APP_PATH/Contents/Frameworks" ]]; then
    while IFS= read -r -d '' framework; do
      /usr/bin/codesign \
        --force \
        --options runtime \
        --timestamp \
        --sign "$MACOS_SIGN_IDENTITY" \
        "$framework"
    done < <(find "$APP_PATH/Contents/Frameworks" -type d -name "*.framework" -print0)
  fi

  /usr/bin/codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$MACOS_SIGN_IDENTITY" \
    "$APP_PATH"

  /usr/bin/codesign --verify --deep --strict "$APP_PATH"
else
  echo "MACOS_SIGN_IDENTITY not set; skipping codesign."
fi

mkdir -p "$DIST_DIR"
hdiutil create \
  -volname "Codex Notifier" \
  -srcfolder "$APP_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "DMG created: $DMG_PATH"
