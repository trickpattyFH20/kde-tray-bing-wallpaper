#!/bin/bash
# Build a self-contained .plasmoid package that bundles the helper,
# systemd units, and wallpaper plugin.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRAY_ID="com.github.trickpattyFH20.bingwallpaper.tray"
PLUGIN_ID="com.github.trickpattyFH20.bingwallpaper"

BUILD_DIR="$(mktemp -d)"
DEST="$BUILD_DIR/$TRAY_ID"
DIST_DIR="$SCRIPT_DIR/dist"

trap 'rm -rf "$BUILD_DIR"' EXIT

echo "=== Building .plasmoid package ==="

# Copy the tray plasmoid structure
cp -r "$SCRIPT_DIR/plasmoid/$TRAY_ID" "$DEST"

# Bundle the helper script
mkdir -p "$DEST/contents/bin"
cp "$SCRIPT_DIR/src/bing-wallpaper-helper" "$DEST/contents/bin/"
chmod +x "$DEST/contents/bin/bing-wallpaper-helper"
# setup script is already in the plasmoid source
chmod +x "$DEST/contents/bin/setup"

# Bundle systemd units
mkdir -p "$DEST/contents/data"
cp "$SCRIPT_DIR/systemd/bing-wallpaper.service" "$DEST/contents/data/"
cp "$SCRIPT_DIR/systemd/bing-wallpaper.timer" "$DEST/contents/data/"

# Bundle the wallpaper plugin
cp -r "$SCRIPT_DIR/plugin/$PLUGIN_ID" "$DEST/contents/data/wallpaper-plugin"

# Build the .plasmoid zip
mkdir -p "$DIST_DIR"
PLASMOID_FILE="$DIST_DIR/bing-wallpaper.plasmoid"
python3 -c "
import zipfile, os, sys
base = sys.argv[1]
name = sys.argv[2]
out = sys.argv[3]
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(os.path.join(base, name)):
        for f in files:
            full = os.path.join(root, f)
            arc = os.path.relpath(full, base)
            zf.write(full, arc)
" "$BUILD_DIR" "$TRAY_ID" "$PLASMOID_FILE"

echo ""
echo "Built: $PLASMOID_FILE"
echo ""
echo "Install with:"
echo "  kpackagetool6 -t Plasma/Applet -i $PLASMOID_FILE"
echo ""
echo "Upgrade with:"
echo "  kpackagetool6 -t Plasma/Applet -u $PLASMOID_FILE"
