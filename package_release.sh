#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

VERSION="1.0.0"
APP_NAME="GEORadarPro.app"
DIST_DIR="$ROOT/dist"
ZIP_OUT="$DIST_DIR/GEORadarPro-v${VERSION}-macOS.zip"
DMG_OUT="$DIST_DIR/GEORadarPro-v${VERSION}-macOS.dmg"
SHA_OUT="$DIST_DIR/SHA256SUMS.txt"

echo "=== [1/4] Building ${APP_NAME} (v${VERSION}) ==="
./build_mac_app.sh

mkdir -p "$DIST_DIR"
rm -f "$ZIP_OUT" "$DMG_OUT" "$SHA_OUT"

echo "=== [2/4] Creating macOS Release ZIP Archive ==="
ditto -c -k --sequesterRsrc --keepParent "$APP_NAME" "$ZIP_OUT"
echo "Created: $ZIP_OUT"

echo "=== [3/4] Creating macOS Drag-and-Drop DMG Installer ==="
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/georadar-dmg.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT

cp -R "$APP_NAME" "$STAGING_DIR/$APP_NAME"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "GEO Radar Pro" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_OUT"

echo "Created: $DMG_OUT"

echo "=== [4/4] Computing SHA-256 Checksums ==="
(
    cd "$DIST_DIR"
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$(basename "$ZIP_OUT")" "$(basename "$DMG_OUT")" > "$SHA_OUT"
    else
        sha256sum "$(basename "$ZIP_OUT")" "$(basename "$DMG_OUT")" > "$SHA_OUT"
    fi
)

cat "$SHA_OUT"
echo "=== Release packaging complete in $DIST_DIR ==="
