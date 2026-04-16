#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRAY_ID="com.github.trickpattyFH20.bingwallpaper.tray"
PLASMOID_FILE="$SCRIPT_DIR/dist/bing-wallpaper.plasmoid"

echo "=== Bing Wallpaper for KDE - Install ==="

# Build the .plasmoid if it doesn't exist
if [ ! -f "$PLASMOID_FILE" ]; then
    echo "Building .plasmoid package..."
    bash "$SCRIPT_DIR/build-plasmoid.sh"
fi

# Install or upgrade the plasmoid
echo "Installing plasmoid..."
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q "$TRAY_ID"; then
    kpackagetool6 -t Plasma/Applet -u "$PLASMOID_FILE"
    echo "Plasmoid upgraded"
else
    kpackagetool6 -t Plasma/Applet -i "$PLASMOID_FILE"
    echo "Plasmoid installed"
fi

# Restart plasmashell so changes take effect
echo "Restarting plasmashell..."
kquitapp6 plasmashell 2>/dev/null || true
sleep 1

# Register applet in the system tray so it appears automatically
echo "Registering in system tray..."
APPLETS_RC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ -f "$APPLETS_RC" ]; then
    if ! grep -q "$TRAY_ID" "$APPLETS_RC"; then
        sed -i "s/^extraItems=\(.*\)/extraItems=\1,$TRAY_ID/" "$APPLETS_RC"
        sed -i "s/^knownItems=\(.*\)/knownItems=\1,$TRAY_ID/" "$APPLETS_RC"
        echo "Applet registered in system tray"
    else
        echo "Applet already registered"
    fi
fi

kstart plasmashell 2>/dev/null &
echo "Plasmashell restarted"

echo ""
echo "=== Installation complete ==="
echo "The plasmoid will auto-setup the systemd timer and wallpaper plugin on first launch."
echo "The system tray applet can be added via the system tray settings."
