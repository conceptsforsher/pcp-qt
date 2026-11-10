// SPDX-License-Identifier: GPL-3.0-only
// Accent-filled button (Qt 5.6 safe: Controls 1.4 + Styles 1.1).
// Replaces Controls 2 Button with highlighted:true.
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.1

import PCP.Style 0.1

Item {
    id: root

    property alias text: button.text
    property alias enabled: button.enabled
    property bool flat: false

    signal clicked

    implicitWidth: 120
    implicitHeight: 40

    Button {
        id: button

        anchors.fill: parent

        onClicked: root.clicked()

        style: ButtonStyle {
            background: Rectangle {
                color: !control.enabled
                       ? (PPalette.dark ? "#3a3a3a" : "#bdbdbd")
                       : (root.flat ? "transparent" : PPalette.accent)
                radius: 2
            }
            label: Text {
                text: control.text
                color: root.flat ? PPalette.accent : "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
