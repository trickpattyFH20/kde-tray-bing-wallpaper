/*
 *  SPDX-FileCopyrightText: 2024 trickpattyFH20
 *  SPDX-License-Identifier: MIT
 *
 *  Bing Wallpaper system tray applet for KDE Plasma.
 */

import QtCore
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    // --- Properties ---
    property var imageList: []
    property int currentIndex: 0
    property string downloadDir: ""
    property bool loading: false
    property bool pendingStartupCheck: false

    // --- Plasmoid config ---
    Plasmoid.icon: "preferences-desktop-wallpaper"
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    switchWidth: Kirigami.Units.gridUnit * 20
    switchHeight: Kirigami.Units.gridUnit * 20

    // --- Right-click context menu actions ---
    // Plasma automatically adds "Configure Bing Wallpaper..." which has
    // General settings and the About page in the sidebar.
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh Now"
            icon.name: "view-refresh"
            onTriggered: root.refresh()
        }
    ]

    // --- Executable data source ---
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(source, data) {
            var stdout = data["stdout"] || "";
            var stderr = data["stderr"] || "";
            executable.disconnectSource(source);
            console.log("Bing Wallpaper: exec result for", source.substring(0, 40), "stdout length:", stdout.length);

            if (source.indexOf("fetch") >= 0) {
                root.loading = false;
                try {
                    var result = JSON.parse(stdout);
                    if (result.dir) {
                        root.downloadDir = result.dir;
                    }
                    root.loadMetadata();
                } catch (e) {
                    console.log("Bing Wallpaper: fetch parse error:", e, stdout);
                }
            } else if (source.indexOf("set-wallpaper") >= 0) {
                root.loadMetadata();
            } else if (source.indexOf("cat ") >= 0 && source.indexOf("metadata.json") >= 0) {
                // Fallback metadata read via cat
                try {
                    var data2 = JSON.parse(stdout);
                    root.imageList = data2.images || [];
                    console.log("Bing Wallpaper: loaded " + root.imageList.length + " images via cat");
                } catch (e) {
                    console.log("Bing Wallpaper: cat parse error:", e);
                }
                // On startup, check if we need to fetch today's wallpaper
                if (root.pendingStartupCheck) {
                    root.pendingStartupCheck = false;
                    if (!root.hasTodayImage()) {
                        console.log("Bing Wallpaper: today's image not found, fetching");
                        root.refresh();
                    } else {
                        console.log("Bing Wallpaper: today's image already available");
                    }
                }
            }
        }
    }

    // --- Reload metadata when popup is opened ---
    onExpandedChanged: {
        if (root.expanded) {
            root.loadMetadata();
        }
    }

    // --- Functions ---
    function refresh() {
        root.loading = true;
        var keep = Plasmoid.configuration.RetentionCount || 0;
        var cmd = "bing-wallpaper-helper fetch --apply";
        if (keep > 0) {
            cmd += " --keep " + keep;
        }
        executable.connectSource(cmd);
    }

    function setWallpaper(index) {
        if (index < 0 || index >= imageList.length) return;
        var img = imageList[index];
        var path = root.downloadDir + "/" + img.filename;
        var cmd = "bing-wallpaper-helper set-wallpaper"
            + " '" + path + "'"
            + " --title '" + (img.title || "").replace(/'/g, "'\\''") + "'"
            + " --copyright '" + (img.copyright || "").replace(/'/g, "'\\''") + "'"
            + " --link '" + (img.copyrightlink || "").replace(/'/g, "'\\''") + "'";
        executable.connectSource(cmd);
        root.currentIndex = index;
    }

    function loadMetadata() {
        // XHR is blocked in Plasma applets — read via executable engine
        executable.connectSource("cat " + root.downloadDir + "/metadata.json");
    }

    function hasTodayImage() {
        if (root.imageList.length === 0) return false;
        var now = new Date();
        var todayStr = now.getFullYear().toString()
            + ("0" + (now.getMonth() + 1)).slice(-2)
            + ("0" + now.getDate()).slice(-2);
        // Use >= so early availability of tomorrow's image counts
        return root.imageList[0].startdate >= todayStr;
    }

    function navigate(delta) {
        var newIndex = currentIndex + delta;
        if (newIndex >= 0 && newIndex < imageList.length) {
            currentIndex = newIndex;
        }
    }

    // --- Helpers ---
    function urlToPath(url) {
        // StandardPaths returns URLs like "file:///home/user/Pictures"
        // Strip the file:// prefix to get a plain path
        var s = url.toString();
        if (s.startsWith("file://")) {
            return s.substring(7);
        }
        return s;
    }

    // --- Startup ---
    Component.onCompleted: {
        var paths = StandardPaths.standardLocations(StandardPaths.PicturesLocation);
        var picturesDir = paths.length > 0
            ? urlToPath(paths[0])
            : urlToPath(StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]) + "/Pictures";
        root.downloadDir = picturesDir + "/bing-wallpapers";

        // Load metadata, then check if we need to fetch today's wallpaper
        root.pendingStartupCheck = true;
        root.loadMetadata();
    }
}
