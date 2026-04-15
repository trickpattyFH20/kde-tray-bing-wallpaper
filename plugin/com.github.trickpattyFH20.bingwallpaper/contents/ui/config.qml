/*
 *   SPDX-FileCopyrightText: 2024 trickpattyFH20
 *   SPDX-License-Identifier: MIT
 *
 *   Configuration UI for the Bing Wallpaper plugin.
 */

import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import Qt.labs.folderlistmodel

import org.kde.kquickcontrols as KQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property string cfg_Image
    property int cfg_FillMode
    property alias cfg_Color: colorButton.color
    property string cfg_Description
    property string cfg_Copyright
    property string cfg_CopyrightLink
    property alias formLayout: root

    onCfg_FillModeChanged: {
        resizeComboBox.setMethod()
    }

    // --- Current wallpaper preview ---
    Item {
        Kirigami.FormData.label: "Current wallpaper:"
        Layout.fillWidth: true
        Layout.preferredHeight: previewImage.height + Kirigami.Units.smallSpacing

        Image {
            id: previewImage
            width: Math.min(parent.width, 400)
            height: width * 9 / 16
            source: cfg_Image
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            visible: cfg_Image.length > 0

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1
                radius: 4
            }
        }

        QQC2.Label {
            anchors.centerIn: parent
            visible: cfg_Image.length === 0
            text: "No wallpaper selected"
            opacity: 0.5
        }
    }

    // Description
    Kirigami.SelectableLabel {
        Kirigami.FormData.label: "Title:"
        Layout.fillWidth: true
        Layout.maximumWidth: 400
        visible: cfg_Description.length > 0
        font.bold: true
        text: cfg_Description
    }

    Kirigami.SelectableLabel {
        Kirigami.FormData.label: "Copyright:"
        Layout.fillWidth: true
        Layout.maximumWidth: 400
        visible: cfg_Copyright.length > 0
        text: cfg_CopyrightLink.length > 0
            ? "<a href=\"" + cfg_CopyrightLink + "\">" + cfg_Copyright + "</a>"
            : cfg_Copyright
        onLinkActivated: function(link) { Qt.openUrlExternally(link) }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    // --- Available images grid (all visible at once) ---
    Item {
        Kirigami.FormData.label: "Available images:"
        Layout.fillWidth: true
        Layout.preferredHeight: imageGrid.implicitHeight + Kirigami.Units.smallSpacing
        visible: folderModel.count > 0

        FolderListModel {
            id: folderModel
            folder: {
                var paths = StandardPaths.standardLocations(StandardPaths.PicturesLocation);
                if (paths.length > 0) {
                    return paths[0] + "/bing-wallpapers";
                }
                return StandardPaths.standardLocations(StandardPaths.HomeLocation)[0] + "/Pictures/bing-wallpapers";
            }
            nameFilters: ["*.jpg", "*.jpeg", "*.png"]
            sortField: FolderListModel.Name
            sortReversed: true
            showDirs: false
        }

        Flow {
            id: imageGrid
            width: parent.width
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: folderModel

                delegate: Item {
                    required property url fileUrl
                    required property string fileName

                    width: 120
                    height: 75

                    Image {
                        id: thumbImage
                        anchors.fill: parent
                        anchors.margins: 2
                        source: parent.fileUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        sourceSize.width: 240
                        sourceSize.height: 150

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: cfg_Image === thumbImage.source.toString()
                                ? Kirigami.Theme.highlightColor
                                : (thumbMouse.containsMouse ? Kirigami.Theme.hoverColor : "transparent")
                            border.width: cfg_Image === thumbImage.source.toString() ? 3 : 2
                            radius: 3
                        }
                    }

                    MouseArea {
                        id: thumbMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cfg_Image = parent.fileUrl.toString()
                            var name = parent.fileName.replace(/^\d{8}_/, "").replace(/_EN-US.*$/, "").replace(/_/g, " ")
                            cfg_Description = name
                        }
                    }

                    QQC2.ToolTip.visible: thumbMouse.containsMouse
                    QQC2.ToolTip.text: {
                        var dateStr = parent.fileName.substring(0, 8)
                        if (dateStr.length === 8) {
                            return dateStr.substring(0, 4) + "-" + dateStr.substring(4, 6) + "-" + dateStr.substring(6, 8)
                        }
                        return parent.fileName
                    }
                }
            }
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    // --- Positioning and color ---
    QQC2.ComboBox {
        id: resizeComboBox
        Kirigami.FormData.label: "Positioning:"
        model: [
            { 'label': "Scaled and cropped", 'fillMode': Image.PreserveAspectCrop },
            { 'label': "Scaled",             'fillMode': Image.Stretch },
            { 'label': "Scaled, keep proportions", 'fillMode': Image.PreserveAspectFit },
            { 'label': "Centered",           'fillMode': Image.Pad },
            { 'label': "Tiled",              'fillMode': Image.Tile }
        ]

        textRole: "label"
        onActivated: cfg_FillMode = model[currentIndex]["fillMode"]
        Component.onCompleted: setMethod()

        function setMethod() {
            for (var i = 0; i < model.length; i++) {
                if (model[i]["fillMode"] === cfg_FillMode) {
                    resizeComboBox.currentIndex = i;
                    return;
                }
            }
            resizeComboBox.currentIndex = 0;
            cfg_FillMode = model[0]["fillMode"];
        }
    }

    KQC2.ColorButton {
        id: colorButton
        Kirigami.FormData.label: "Background color:"
        dialogTitle: "Select Background Color"
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    // --- About ---
    Kirigami.SelectableLabel {
        Kirigami.FormData.label: "About:"
        text: "<b>Bing Wallpaper</b> v0.1.0<br>" +
              "<a href=\"https://github.com/trickpattyFH20/kde-tray-bing-wallpaper\">GitHub</a>"
        onLinkActivated: function(link) { Qt.openUrlExternally(link) }
    }

    QQC2.Label {
        Layout.fillWidth: true
        Layout.maximumWidth: 400
        wrapMode: Text.Wrap
        text: "Tip: Right-click the Bing Wallpaper tray icon and select 'Configure Bing Wallpaper...' for refresh interval, retention, and other settings."
        opacity: 0.6
        font.italic: true
    }
}
