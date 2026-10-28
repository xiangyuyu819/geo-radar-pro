#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "[1/5] Building GEORadarPro release binary..."
swift build -c release
BIN="$(swift build -c release --show-bin-path)/GEORadarPro"

APP="$ROOT/GEORadarPro.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "[2/5] Copying executable and embedded Python engine..."
cp "$BIN" "$APP/Contents/MacOS/GEORadarPro"
cp "$ROOT/scripts/geo_engine.py" "$APP/Contents/Resources/geo_engine.py"
chmod +x "$APP/Contents/MacOS/GEORadarPro" "$APP/Contents/Resources/geo_engine.py"

echo "[3/5] Generating macOS AppIcon.icns (if assets/AppIcon-1024.png and sips/iconutil exist)..."
ICON_SRC="$ROOT/assets/AppIcon-1024.png"
if [ -f "$ICON_SRC" ] && command -v sips >/dev/null 2>&1 && command -v iconutil >/dev/null 2>&1; then
    ICONSET_DIR="$ROOT/build/AppIcon.iconset"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"

    sips -z 16 16     "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
    sips -z 32 32     "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
    sips -z 32 32     "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
    sips -z 64 64     "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
    sips -z 64 64     "$ICON_SRC" --out "$ICONSET_DIR/icon_64x64.png" >/dev/null
    sips -z 128 128   "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
    sips -z 256 256   "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
    sips -z 256 256   "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
    sips -z 512 512   "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
    sips -z 512 512   "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
    sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

    iconutil -c icns "$ICONSET_DIR" -o "$APP/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONSET_DIR"
    echo "Generated $APP/Contents/Resources/AppIcon.icns"
else
    echo "Skipping .icns conversion (sips/iconutil not found or non-macOS host); copying PNG icon fallback."
    if [ -f "$ICON_SRC" ]; then
        cp "$ICON_SRC" "$APP/Contents/Resources/AppIcon-1024.png"
    fi
fi

echo "[4/5] Writing Info.plist (version 1.0.0)..."
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>GEORadarPro</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.georadar.pro</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>GEORadarPro</string>
    <key>CFBundleDisplayName</key>
    <string>GEO Radar Pro</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>100</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "[5/5] Ad-hoc signing app bundle (if codesign available)..."
if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$APP" || true
fi

echo "Built $APP (v1.0.0)"
