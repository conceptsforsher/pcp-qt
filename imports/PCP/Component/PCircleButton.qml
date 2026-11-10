// SPDX-License-Identifier: GPL-3.0-only
// Round accent icon button (Qt 5.6 safe, pure QtQuick).
// Replaces Controls 2 RoundButton.
import QtQuick 2.6

import PCP.Component 2.0
import PCP.Style 0.1

Item {
    id: root

    property alias icon: buttonIcon.icon

    signal clicked

    width: 64
    height: 64

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: PPalette.accent
    }

    MaterialIcon {
        id: buttonIcon

        anchors.fill: parent
        anchors.margins: 12
        color: "white"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
