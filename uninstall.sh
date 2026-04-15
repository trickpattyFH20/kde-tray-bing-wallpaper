#!/bin/bash
set -e

PLUGIN_ID="com.github.trickpattyFH20.bingwallpaper"
TRAY_ID="com.github.trickpattyFH20.bingwallpaper.tray"
PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/$PLUGIN_ID"
HELPER_BIN="$HOME/.local/bin/bing-wallpaper-helper"
DEFAULT_IMAGES="$HOME/Pictures/bing-wallpapers"
CONFIG_DIR="$HOME/.config/bing-wallpaper"

# Also clean up legacy files from the old Python app
LEGACY_AUTOSTART="$HOME/.config/autostart/bing-wallpaper.desktop"
LEGACY_BIN="$HOME/.local/bin/bing-wallpaper"
LEGACY_DIR="$HOME/.local/share/bing-wallpaper"

echo "=== Bing Wallpaper for KDE - Uninstall ==="

# Disable and remove systemd timer
if systemctl --user is-enabled bing-wallpaper.timer &>/dev/null; then
    echo "Disabling systemd timer..."
    systemctl --user disable --now bing-wallpaper.timer
    echo "Timer disabled"
fi
rm -f "$HOME/.config/systemd/user/bing-wallpaper.timer"
rm -f "$HOME/.config/systemd/user/bing-wallpaper.service"
systemctl --user daemon-reload 2>/dev/null || true

# Remove helper script
if [ -f "$HELPER_BIN" ]; then
    echo "Removing bing-wallpaper-helper..."
    rm -f "$HELPER_BIN"
    echo "Helper removed"
fi

# Remove system tray plasmoid
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q "$TRAY_ID"; then
    echo "Removing system tray plasmoid..."
    kpackagetool6 -t Plasma/Applet -r "$TRAY_ID"
    echo "Plasmoid removed"
else
    echo "Plasmoid not found, skipping"
fi

# Remove KDE wallpaper plugin
if [ -d "$PLUGIN_DIR" ]; then
    echo "Removing KDE wallpaper plugin..."
    rm -rf "$PLUGIN_DIR"
    echo "Plugin removed"
else
    echo "Plugin not found, skipping"
fi

# Remove config
if [ -d "$CONFIG_DIR" ]; then
    echo "Removing configuration..."
    rm -rf "$CONFIG_DIR"
fi

# Clean up legacy Python app (if present from older installs)
if command -v pipx &>/dev/null && pipx list 2>/dev/null | grep -q kde-tray-bing-wallpaper; then
    echo "Removing legacy Python package..."
    pipx uninstall kde-tray-bing-wallpaper
fi
[ -d "$LEGACY_DIR" ] && rm -rf "$LEGACY_DIR"
[ -f "$LEGACY_BIN" ] && rm -f "$LEGACY_BIN"
[ -f "$LEGACY_AUTOSTART" ] && rm -f "$LEGACY_AUTOSTART"

# Ask about downloaded images
if [ -d "$DEFAULT_IMAGES" ]; then
    echo ""
    read -p "Delete downloaded wallpaper images in $DEFAULT_IMAGES? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$DEFAULT_IMAGES"
        echo "Downloaded images removed"
    else
        echo "Downloaded images kept at $DEFAULT_IMAGES"
    fi
fi

echo ""
echo "=== Uninstall complete ==="
echo "You may need to change your wallpaper type in Desktop Settings."
