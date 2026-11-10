// SPDX-License-Identifier: GPL-3.0-only
// Clickable row/icon (Qt 5.6 safe, pure QtQuick).
// Replaces Controls 2 ItemDelegate (contentItem / text / onClicked).
import QtQuick 2.6

import PCP.Style 0.1

Item {
    id: root

    property var contentItem
    property string text: ""
    property bool highlighted: false
    property bool enabled: true

    signal clicked

    onContentItemChanged: {
        if (contentItem) {
            contentItem.parent = contentHolder
            contentItem.anchors.fill = contentHolder
        }
    }

    Rectangle {
        anchors.fill: parent
        color: PPalette.accent
        opacity: 0.15
        visible: root.highlighted
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        opacity: 0.08
        visible: mouseArea.containsMouse && mouseArea.pressed

        id: pressedFeedback
    }

    Text {
        anchors.fill: parent
        anchors.margins: 8

        text: root.text
        color: PPalette.foreground
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight

        visible: root.text !== ""
    }

    Item {
        id: contentHolder

        anchors.fill: parent
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled

        onClicked: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        color: PPalette.background
        opacity: 0.6
        visible: !root.enabled
    }
}
