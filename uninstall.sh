#!/bin/bash
set -e

PLUGIN_ID="com.github.trickpattyFH20.bingwallpaper"
TRAY_ID="com.github.trickpattyFH20.bingwallpaper.tray"
PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/$PLUGIN_ID"
HELPER_BIN="$HOME/.local/bin/bing-wallpaper-helper"
DEFAULT_IMAGES="$HOME/Pictures/bing-wallpapers"
CONFIG_DIR="$HOME/.config/bing-wallpaper"
APPLETS_RC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

# Also clean up legacy files from the old Python app
LEGACY_AUTOSTART="$HOME/.config/autostart/bing-wallpaper.desktop"
LEGACY_BIN="$HOME/.local/bin/bing-wallpaper"
LEGACY_DIR="$HOME/.local/share/bing-wallpaper"

# On modern Plasma 6 sessions (Wayland in particular) plasmashell is managed by
# systemd; quitting it and relaunching a bare instance leaves an unmanaged
# process that fails to draw. Use the systemd unit when it's present.
plasmashell_is_systemd() {
    systemctl --user cat plasma-plasmashell.service &>/dev/null
}

stop_plasmashell() {
    if plasmashell_is_systemd; then
        systemctl --user stop plasma-plasmashell.service
    else
        kquitapp6 plasmashell 2>/dev/null || true
        sleep 1
    fi
}

start_plasmashell() {
    if plasmashell_is_systemd; then
        systemctl --user start plasma-plasmashell.service
    else
        kstart plasmashell 2>/dev/null &
    fi
}

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

# Remove KDE wallpaper plugin. If any desktop is currently using it as its
# wallpaper, removing the package would leave that desktop unable to draw
# (black screen), so reset those containments back to the stock image
# wallpaper first. Config edits must happen while plasmashell is stopped,
# otherwise the running instance overwrites the file when it next saves.
WALLPAPER_IN_USE=false
if [ -f "$APPLETS_RC" ] && grep -q "^wallpaperplugin=$PLUGIN_ID$" "$APPLETS_RC"; then
    WALLPAPER_IN_USE=true
    echo "Bing wallpaper is the active desktop wallpaper; resetting to default..."
    stop_plasmashell
    sed -i "s/^wallpaperplugin=$PLUGIN_ID$/wallpaperplugin=org.kde.image/" "$APPLETS_RC"
    echo "Desktop wallpaper reset to org.kde.image"
fi

if [ -d "$PLUGIN_DIR" ]; then
    echo "Removing KDE wallpaper plugin..."
    rm -rf "$PLUGIN_DIR"
    echo "Plugin removed"
else
    echo "Plugin not found, skipping"
fi

# Bring plasmashell back if we stopped it to rewrite the wallpaper config.
if [ "$WALLPAPER_IN_USE" = true ]; then
    echo "Restarting plasmashell..."
    start_plasmashell
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
