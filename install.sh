#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRAY_ID="com.github.trickpattyFH20.bingwallpaper.tray"
PLASMOID_FILE="$SCRIPT_DIR/dist/$TRAY_ID.plasmoid"

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

# On modern Plasma 6 sessions (Wayland in particular) plasmashell is managed by
# systemd; quitting it with `kquitapp6` and relaunching a bare `kstart
# plasmashell` launches outside the session environment, falls back to the xcb
# backend with no display, and aborts (the unit runs --no-respawn, so the panel
# then stays dead until a manual restart). Drive it through the systemd unit when
# it's present, and fall back to the kquitapp6/kstart pattern only on older (X11)
# setups that aren't systemd-managed.
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

# Stop plasmashell, register the applet, then start it again. The system tray
# config must be edited while plasmashell is stopped, otherwise the running
# instance overwrites the file when it next saves its state.
echo "Restarting plasmashell..."
stop_plasmashell

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

start_plasmashell
echo "Plasmashell restarted"

echo ""
echo "=== Installation complete ==="
echo "The plasmoid will auto-setup the systemd timer and wallpaper plugin on first launch."
echo "The system tray applet can be added via the system tray settings."
