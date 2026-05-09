/*
 *  SPDX-FileCopyrightText: 2024 trickpattyFH20
 *  SPDX-License-Identifier: MIT
 */

import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

Kirigami.FormLayout {
    id: configRoot

    property alias cfg_RetentionCount: retentionCombo.currentValue

    readonly property string helperPath: {
        var url = Qt.resolvedUrl("../../bin/bing-wallpaper-helper").toString();
        if (url.startsWith("file://")) url = url.substring(7);
        return url;
    }

    property string loginSyncStatus: ""

    Plasma5Support.DataSource {
        id: configExec
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var stdout = (data["stdout"] || "").trim();
            var stderr = (data["stderr"] || "").trim();
            configExec.disconnectSource(source);

            if (source.indexOf("setup-login-screen") >= 0) {
                var enabled = source.indexOf("--enable") >= 0;
                try {
                    var r = JSON.parse(stdout);
                    if (r.ok) {
                        configRoot.loginSyncStatus = enabled
                            ? "Enabled. Login screen will update on the next wallpaper change."
                            : "Disabled. Reverted to Picture of the Day (Bing).";
                    } else if (r.error) {
                        configRoot.loginSyncStatus = "Failed: " + r.error;
                        loginScreenSync.checked = !enabled;
                    }
                } catch (e) {
                    configRoot.loginSyncStatus = stderr || "Cancelled or failed.";
                    loginScreenSync.checked = !enabled;
                }
            }
        }
    }

    Plasma5Support.DataSource {
        id: loginSyncCheck
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var stdout = (data["stdout"] || "").trim();
            loginSyncCheck.disconnectSource(source);
            loginScreenSync.checked = (stdout === "yes");
        }
    }

    Plasma5Support.DataSource {
        id: lockSyncExec
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            lockSyncExec.disconnectSource(source);
        }
    }

    Plasma5Support.DataSource {
        id: lockSyncCheck
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var stdout = (data["stdout"] || "").trim();
            lockSyncCheck.disconnectSource(source);
            lockScreenSync.checked = (stdout === "yes");
        }
    }

    Component.onCompleted: {
        loginSyncCheck.connectSource("test -d /var/lib/bing-wallpaper && echo yes || echo no");
        lockSyncCheck.connectSource("test -f ~/.config/bing-wallpaper/sync-lockscreen && echo yes || echo no");
    }

    // Top padding
    Item {
        Kirigami.FormData.isSection: true
        height: Kirigami.Units.largeSpacing
    }

    QQC2.Label {
        Kirigami.FormData.label: "Refresh schedule:"
        text: "New wallpapers are fetched automatically at midnight\nPacific Time each day via a systemd timer."
        wrapMode: Text.Wrap
        opacity: 0.7
    }

    QQC2.ComboBox {
        id: retentionCombo
        Kirigami.FormData.label: "Keep images:"
        model: [
            { text: "5 images",    value: 5 },
            { text: "10 images",   value: 10 },
            { text: "30 images",   value: 30 },
            { text: "50 images",   value: 50 },
            { text: "100 images",  value: 100 },
            { text: "Keep all",    value: 0 }
        ]
        textRole: "text"
        valueRole: "value"

        Component.onCompleted: {
            for (var i = 0; i < model.length; i++) {
                if (model[i].value === cfg_RetentionCount) {
                    currentIndex = i;
                    return;
                }
            }
            currentIndex = 2; // default: 30
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    // --- Images directory ---
    QQC2.Label {
        Kirigami.FormData.label: "Images directory:"
        text: {
            var paths = StandardPaths.standardLocations(StandardPaths.PicturesLocation);
            var dir = paths.length > 0 ? paths[0] : "";
            var s = dir.toString();
            if (s.startsWith("file://")) s = s.substring(7);
            return s + "/bing-wallpapers";
        }
        opacity: 0.7
    }

    QQC2.Button {
        text: "Open Folder"
        icon.name: "folder-open"
        onClicked: {
            var paths = StandardPaths.standardLocations(StandardPaths.PicturesLocation);
            var dir = paths.length > 0 ? paths[0] : "";
            var s = dir.toString();
            if (s.startsWith("file://")) s = s.substring(7);
            configExec.connectSource("xdg-open " + s + "/bing-wallpapers");
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: loginScreenSync
        Kirigami.FormData.label: "Login screen:"
        text: "Sync wallpaper to login screen"
        onClicked: {
            var flag = checked ? "--enable" : "--disable";
            configRoot.loginSyncStatus = "Awaiting authentication…";
            configExec.connectSource("'" + configRoot.helperPath + "' setup-login-screen " + flag);
        }
    }

    QQC2.Label {
        text: configRoot.loginSyncStatus.length > 0
            ? configRoot.loginSyncStatus
            : "Asks for your password each time. Takes effect on next logout/reboot."
        wrapMode: Text.Wrap
        opacity: 0.7
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: lockScreenSync
        Kirigami.FormData.label: "Lock screen:"
        text: "Sync wallpaper to lock screen"
        onClicked: {
            var flag = checked ? "--enable" : "--disable";
            lockSyncExec.connectSource("'" + configRoot.helperPath + "' set-lock-screen-sync " + flag);
        }
    }

    QQC2.Label {
        text: "Updates the lock screen wallpaper alongside the desktop. Takes effect on the next lock."
        wrapMode: Text.Wrap
        opacity: 0.7
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    QQC2.Button {
        Kirigami.FormData.label: "Database:"
        text: "Reset (delete all images)"
        icon.name: "edit-delete"
        onClicked: resetDialog.open()
    }

    QQC2.Dialog {
        id: resetDialog
        title: "Reset Database"
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        anchors.centerIn: Overlay.overlay

        QQC2.Label {
            text: "This will delete all downloaded wallpaper images and metadata.\nAre you sure?"
            wrapMode: Text.Wrap
        }

        onAccepted: {
            configExec.connectSource("'" + configRoot.helperPath + "' cleanup --keep 0")
        }
    }
}
