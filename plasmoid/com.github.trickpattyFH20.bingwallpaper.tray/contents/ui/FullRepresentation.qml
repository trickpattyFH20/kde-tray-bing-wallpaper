/*
 *  SPDX-FileCopyrightText: 2024 trickpattyFH20
 *  SPDX-License-Identifier: MIT
 *
 *  Full popup representation — image preview, navigation, wallpaper selection.
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

PlasmaExtras.Representation {
    id: fullRoot

    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
    Layout.minimumHeight: Kirigami.Units.gridUnit * 24
    Layout.preferredHeight: Kirigami.Units.gridUnit * 40

    property var currentImage: root.imageList.length > 0 ? root.imageList[root.currentIndex] : null
    property string currentImagePath: currentImage
        ? "file://" + root.downloadDir + "/" + currentImage.filename
        : ""

    // Max content width — the popup is resizable by the system tray,
    // so we cap the content and center it instead.
    readonly property real maxContentWidth: Kirigami.Units.gridUnit * 24

    header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent

            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 3
                text: "Bing Wallpaper"
            }

            PlasmaComponents3.Button {
                icon.name: "view-refresh"
                text: "Refresh"
                enabled: !root.loading
                onClicked: root.refresh()
            }
        }
    }

    // Scrollable content — fills whatever height the system tray gives us
    QQC2.ScrollView {
        id: scrollView
        anchors.fill: parent
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        Flickable {
            contentWidth: availableWidth
            contentHeight: contentColumn.implicitHeight
            clip: true

            ColumnLayout {
                id: contentColumn
                width: Math.min(scrollView.availableWidth, fullRoot.maxContentWidth)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Kirigami.Units.smallSpacing

                // --- Image preview ---
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 9 / 16
                    Layout.topMargin: Kirigami.Units.gridUnit
                    color: Kirigami.Theme.backgroundColor
                    radius: Kirigami.Units.smallSpacing

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: fullRoot.currentImagePath
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true

                        QQC2.BusyIndicator {
                            anchors.centerIn: parent
                            running: root.loading && root.imageList.length === 0
                            visible: running
                        }

                        PlasmaComponents3.Label {
                            anchors.centerIn: parent
                            visible: root.imageList.length === 0 && !root.loading
                            text: "No images yet"
                            opacity: 0.5
                        }
                    }
                }

                // --- Title + Copyright (fixed height so content doesn't jump) ---
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 4

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.TextArea {
                            Layout.fillWidth: true
                            text: fullRoot.currentImage ? fullRoot.currentImage.title : ""
                            font.bold: true
                            wrapMode: Text.Wrap
                            readOnly: true
                            selectByMouse: true
                            background: null
                            padding: 0
                        }

                        Text {
                            Layout.fillWidth: true
                            text: {
                                if (!fullRoot.currentImage) return "";
                                var c = fullRoot.currentImage.copyright || "";
                                var link = fullRoot.currentImage.copyrightlink || "";
                                return link ? "<a href=\"" + link + "\" style=\"color: #5b9bd5;\">" + c + "</a>" : c;
                            }
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.textColor
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            opacity: 0.7
                            onLinkActivated: function(link) { Qt.openUrlExternally(link) }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }

                // --- Navigation ---
                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents3.Button {
                        text: "\u25c0 Older"
                        enabled: root.currentIndex < root.imageList.length - 1
                        onClicked: { root.navigate(1); root.setWallpaper(root.currentIndex); }
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                            if (!fullRoot.currentImage) return "";
                            var d = fullRoot.currentImage.startdate || "";
                            if (d.length === 8) {
                                return d.substring(0, 4) + "-" + d.substring(4, 6) + "-" + d.substring(6, 8)
                                    + "  (" + (root.currentIndex + 1) + "/" + root.imageList.length + ")";
                            }
                            return d;
                        }
                    }

                    PlasmaComponents3.Button {
                        text: "Newer \u25b6"
                        enabled: root.currentIndex > 0
                        onClicked: { root.navigate(-1); root.setWallpaper(root.currentIndex); }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true }

                // --- Thumbnails ---
                PlasmaComponents3.Label {
                    text: "Available images"
                    font.bold: true
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    // Center thumbnails by calculating even side margins
                    property real thumbWidth: Kirigami.Units.gridUnit * 7
                    property int cols: Math.max(1, Math.floor((contentColumn.width + spacing) / (thumbWidth + spacing)))
                    property real usedWidth: cols * thumbWidth + (cols - 1) * spacing
                    property real sideMargin: Math.max(0, (contentColumn.width - usedWidth) / 2)

                    Layout.leftMargin: sideMargin
                    Layout.rightMargin: sideMargin

                    Repeater {
                        model: root.imageList

                        delegate: Item {
                            width: Kirigami.Units.gridUnit * 7
                            height: Kirigami.Units.gridUnit * 4

                            required property int index
                            required property var modelData

                            Image {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                source: "file://" + root.downloadDir + "/" + modelData.filename
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                sourceSize.width: 240
                                sourceSize.height: 135

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.color: parent.parent.index === root.currentIndex
                                        ? Kirigami.Theme.highlightColor
                                        : (thumbMouse.containsMouse ? Kirigami.Theme.hoverColor : "transparent")
                                    border.width: parent.parent.index === root.currentIndex ? 3 : 2
                                    radius: Kirigami.Units.smallSpacing
                                }
                            }

                            MouseArea {
                                id: thumbMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { root.currentIndex = parent.index; root.setWallpaper(parent.index); }
                            }

                            QQC2.ToolTip.visible: thumbMouse.containsMouse
                            QQC2.ToolTip.text: {
                                var d = modelData.startdate || "";
                                var t = modelData.title || "";
                                if (d.length === 8) {
                                    return d.substring(0, 4) + "-" + d.substring(4, 6) + "-" + d.substring(6, 8) + "  " + t;
                                }
                                return t;
                            }
                        }
                    }
                }
            }
        }
    }
}
