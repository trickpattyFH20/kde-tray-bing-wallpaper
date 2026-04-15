# Maintainer: trickpattyFH20 <patricktlawler@gmail.com>
pkgname=kde-tray-bing-wallpaper
pkgver=0.1.0
pkgrel=1
pkgdesc='KDE Plasma system tray app and wallpaper plugin for daily Bing wallpapers'
arch=('any')
url='https://github.com/trickpattyFH20/kde-tray-bing-wallpaper'
license=('MIT')
depends=('python' 'plasma-workspace')
source=("$pkgname-$pkgver.tar.gz::$url/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
    cd "$pkgname-$pkgver"

    # Install helper script
    install -Dm755 src/bing-wallpaper-helper \
        "$pkgdir/usr/bin/bing-wallpaper-helper"

    # Install KDE wallpaper plugin
    local plugin_id="com.github.trickpattyFH20.bingwallpaper"
    install -dm755 "$pkgdir/usr/share/plasma/wallpapers/$plugin_id/contents/config"
    install -dm755 "$pkgdir/usr/share/plasma/wallpapers/$plugin_id/contents/ui"
    install -Dm644 "plugin/$plugin_id/metadata.json" \
        "$pkgdir/usr/share/plasma/wallpapers/$plugin_id/metadata.json"
    install -Dm644 "plugin/$plugin_id/contents/config/main.xml" \
        "$pkgdir/usr/share/plasma/wallpapers/$plugin_id/contents/config/main.xml"
    install -Dm644 "plugin/$plugin_id/contents/ui/main.qml" \
        "$pkgdir/usr/share/plasma/wallpapers/$plugin_id/contents/ui/main.qml"
    install -Dm644 "plugin/$plugin_id/contents/ui/config.qml" \
        "$pkgdir/usr/share/plasma/wallpapers/$plugin_id/contents/ui/config.qml"

    # Install system tray plasmoid
    local tray_id="com.github.trickpattyFH20.bingwallpaper.tray"
    local tray_dest="$pkgdir/usr/share/plasma/plasmoids/$tray_id"
    install -Dm644 "plasmoid/$tray_id/metadata.json" \
        "$tray_dest/metadata.json"
    install -Dm644 "plasmoid/$tray_id/contents/config/main.xml" \
        "$tray_dest/contents/config/main.xml"
    install -Dm644 "plasmoid/$tray_id/contents/config/config.qml" \
        "$tray_dest/contents/config/config.qml"
    install -Dm644 "plasmoid/$tray_id/contents/ui/main.qml" \
        "$tray_dest/contents/ui/main.qml"
    install -Dm644 "plasmoid/$tray_id/contents/ui/FullRepresentation.qml" \
        "$tray_dest/contents/ui/FullRepresentation.qml"
    install -Dm644 "plasmoid/$tray_id/contents/ui/CompactRepresentation.qml" \
        "$tray_dest/contents/ui/CompactRepresentation.qml"
    install -Dm644 "plasmoid/$tray_id/contents/ui/config/ConfigGeneral.qml" \
        "$tray_dest/contents/ui/config/ConfigGeneral.qml"

    # Install systemd user timer for automatic daily fetching
    install -Dm644 systemd/bing-wallpaper.timer \
        "$pkgdir/usr/lib/systemd/user/bing-wallpaper.timer"
    # Patch service to use system-wide path instead of ~/.local/bin
    sed 's|%h/.local/bin/bing-wallpaper-helper|/usr/bin/bing-wallpaper-helper|' \
        systemd/bing-wallpaper.service \
        | install -Dm644 /dev/stdin "$pkgdir/usr/lib/systemd/user/bing-wallpaper.service"
}
