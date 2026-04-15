#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ID="com.github.trickpattyFH20.bingwallpaper"
TRAY_ID="com.github.trickpattyFH20.bingwallpaper.tray"
PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/$PLUGIN_ID"
BIN_DIR="$HOME/.local/bin"

echo "=== Bing Wallpaper for KDE - Install ==="

# Install helper script (used by the Plasma applet)
echo "Installing bing-wallpaper-helper..."
mkdir -p "$BIN_DIR"
install -m755 "$SCRIPT_DIR/src/bing-wallpaper-helper" "$BIN_DIR/bing-wallpaper-helper"
echo "Helper installed to $BIN_DIR/bing-wallpaper-helper"

if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo ""
    echo "NOTE: $BIN_DIR is not on your PATH."
    echo "Add this to your ~/.zshrc or ~/.bashrc:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Install KDE wallpaper plugin
echo "Installing KDE wallpaper plugin..."
mkdir -p "$PLUGIN_DIR"
cp -r "$SCRIPT_DIR/plugin/$PLUGIN_ID/"* "$PLUGIN_DIR/"
echo "Plugin installed to $PLUGIN_DIR"

# Install systemd timer for automatic daily fetching
echo "Installing systemd timer..."
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"
install -m644 "$SCRIPT_DIR/systemd/bing-wallpaper.timer" "$SYSTEMD_USER_DIR/"
install -m644 "$SCRIPT_DIR/systemd/bing-wallpaper.service" "$SYSTEMD_USER_DIR/"
systemctl --user daemon-reload
systemctl --user enable --now bing-wallpaper.timer
echo "Timer installed and enabled (next fire: $(systemctl --user list-timers bing-wallpaper.timer --no-legend | awk '{print $1, $2, $3}'))"

# Install system tray plasmoid
echo "Installing system tray plasmoid..."
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q "$TRAY_ID"; then
    kpackagetool6 -t Plasma/Applet -u "$SCRIPT_DIR/plasmoid/$TRAY_ID"
    echo "Plasmoid upgraded"
else
    kpackagetool6 -t Plasma/Applet -i "$SCRIPT_DIR/plasmoid/$TRAY_ID"
    echo "Plasmoid installed"
fi

# Restart plasmashell so changes take effect
# Must quit first, THEN edit config — plasmashell writes config on exit,
# which would overwrite our changes if we edited before quitting.
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
echo "The wallpaper plugin will appear in Desktop Settings > Wallpaper > Type."
echo "The system tray applet can be added via the system tray settings."
