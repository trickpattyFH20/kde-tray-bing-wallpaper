/*
 *   SPDX-FileCopyrightText: 2024 trickpattyFH20
 *   SPDX-License-Identifier: MIT
 *
 *   Bing Wallpaper plugin for KDE Plasma
 *   Displays wallpaper images managed by the Bing Wallpaper tray application.
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Window

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

    contextualActions: [
        PlasmaCore.Action {
            text: "Open Wallpaper Image"
            icon.name: "document-open"
            enabled: root.configuration.Image.length > 0
            onTriggered: Qt.openUrlExternally(root.configuration.Image)
        },
        PlasmaCore.Action {
            text: "View on Bing"
            icon.name: "internet-web-browser"
            enabled: root.configuration.CopyrightLink.length > 0
            onTriggered: Qt.openUrlExternally(root.configuration.CopyrightLink)
        }
    ]

    Rectangle {
        id: backgroundColor
        anchors.fill: parent
        color: root.configuration.Color
        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.longDuration }
        }
    }

    QQC2.StackView {
        id: imageView
        anchors.fill: parent

        readonly property int fillMode: root.configuration.FillMode
        readonly property string imageSource: root.configuration.Image
        readonly property size sourceSize: Qt.size(
            imageView.width * Screen.devicePixelRatio,
            imageView.height * Screen.devicePixelRatio
        )
        property Item pendingImage
        property bool doesSkipAnimation: true

        onFillModeChanged: Qt.callLater(imageView.loadImage)
        onSourceSizeChanged: Qt.callLater(imageView.loadImage)
        onImageSourceChanged: Qt.callLater(imageView.loadImage)

        function loadImage() {
            if (imageSource.length === 0) {
                return;
            }

            if (imageView.pendingImage) {
                imageView.pendingImage.statusChanged.disconnect(replaceWhenLoaded);
                imageView.pendingImage.destroy();
                imageView.pendingImage = null;
            }

            imageView.doesSkipAnimation = imageView.empty;
            imageView.pendingImage = imageComponent.createObject(imageView, {
                "source": imageSource,
                "fillMode": imageView.fillMode,
                "opacity": imageView.doesSkipAnimation ? 1 : 0,
                "sourceSize": imageView.sourceSize,
                "width": imageView.width,
                "height": imageView.height,
            });
            imageView.pendingImage.statusChanged.connect(imageView.replaceWhenLoaded);
            imageView.replaceWhenLoaded();
        }

        function replaceWhenLoaded() {
            if (imageView.pendingImage.status === Image.Loading) {
                return;
            }
            imageView.pendingImage.statusChanged.disconnect(imageView.replaceWhenLoaded);
            imageView.replace(
                imageView.pendingImage,
                {},
                imageView.doesSkipAnimation ? QQC2.StackView.Immediate : QQC2.StackView.Transition
            );
            imageView.pendingImage = null;
        }

        Component {
            id: imageComponent

            Image {
                asynchronous: true
                cache: false
                autoTransform: true
                smooth: true

                QQC2.StackView.onActivated: root.accentColorChanged()
                QQC2.StackView.onDeactivated: destroy()
                QQC2.StackView.onRemoved: destroy()
            }
        }

        replaceEnter: Transition {
            OpacityAnimator {
                id: replaceEnterOpacityAnimator
                to: 1
                duration: Math.round(Kirigami.Units.veryLongDuration * 5)
            }
        }
        replaceExit: Transition {
            PauseAnimation {
                duration: replaceEnterOpacityAnimator.duration + 500
            }
        }
    }
}
