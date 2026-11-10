// SPDX-License-Identifier: GPL-3.0-only
// Modal centered dialog (Qt 5.6 safe, pure QtQuick + PButton).
//
// Replaces Controls 2 Dialog (title / contentItem / standardButtons /
// modal / parent: ApplicationWindow.overlay). The dialog fills its parent,
// dims it, and shows a centered card. With showButtons:false it also closes
// on outside click (replaces Controls 2 Popup closePolicy usage).
import QtQuick 2.6

import PCP.Component 2.0
import PCP.Style 0.1

Item {
    id: root

    anchors.fill: parent
    visible: false
    z: 1000

    property string title: ""
    property bool showButtons: true
    property string acceptText: "OK"
    property string rejectText: "Cancel"
    property int maxWidth: 360
    property var contentItem

    signal accepted
    signal rejected

    function open() { root.visible = true }
    function close() { root.visible = false }

    onContentItemChanged: {
        if (contentItem) {
            contentItem.parent = body
            contentItem.width = Qt.binding(function() { return body.width })
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!root.showButtons)
                    root.close()
            }
        }
    }

    Rectangle {
        id: card

        width: Math.min(root.width - 64, root.maxWidth)
        height: contentColumn.implicitHeight + 32
        anchors.centerIn: parent

        color: PPalette.card
        radius: 2

        Column {
            id: contentColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 12

            Text {
                width: parent.width
                wrapMode: Text.Wrap

                text: root.title
                color: PPalette.foreground
                font.bold: true
                font.pointSize: 12

                visible: root.title !== ""
            }

            Item {
                id: body

                width: parent.width
                height: childrenRect.height
            }

            Row {
                anchors.right: parent.right
                spacing: 8

                visible: root.showButtons

                PButton {
                    width: 96
                    height: 36
                    flat: true
                    text: root.rejectText

                    onClicked: {
                        root.rejected()
                        root.close()
                    }
                }

                PButton {
                    width: 96
                    height: 36
                    text: root.acceptText

                    onClicked: {
                        root.accepted()
                        root.close()
                    }
                }
            }
        }
    }
}
