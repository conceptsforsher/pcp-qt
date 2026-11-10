// SPDX-License-Identifier: GPL-3.0-only
// Right-edge slide-in panel (Qt 5.6 safe, pure QtQuick).
//
// Replaces Controls 2 Drawer (edge / interactive / open() / close()).
// The drawer fills its parent with a dim layer plus a panel on the right.
// Content is assigned explicitly, e.g. `ColumnLayout { parent: drawer.panel
// anchors.fill: parent ... }`; extra overlays (dialogs) go to `drawer`
// itself. Set panelWidth from the caller.
import QtQuick 2.6

import PCP.Style 0.1

Item {
    id: root

    anchors.fill: parent
    visible: false
    z: 100

    property int panelWidth: 320
    property alias panel: panel

    signal opened
    signal closed

    function open() {
        root.visible = true
        panel.x = root.width - panel.width
        root.opened()
    }

    function close() {
        root.visible = false
        panel.x = root.width
        root.closed()
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.4

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: panel

        width: root.panelWidth
        height: parent.height
        x: root.width

        color: PPalette.card

        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }
}
