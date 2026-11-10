// SPDX-License-Identifier: GPL-3.0-only
// Reaction pills under a message (Qt 5.6 safe, pure QtQuick).
// Ported from Spectral (Jul 2019); Controls 2 Control/ToolTip replaced.
import QtQuick 2.6
import QtQuick.Layouts 1.2

import PCP.Setting 0.1
import PCP.Style 0.1

Item {
    id: root

    // FORK-ONLY: declare the role so that a row without it yields an empty
    // list. Without this, a missing role produced ReferenceError/undefined,
    // `visible` became non-boolean, and QtQuick.Layouts re-ran layout
    // forever (UI hang + endless "Unable to assign [undefined] to bool").
    property var reaction: []

    // Always a real bool - never undefined.
    readonly property bool hasReactions: !!(reaction && reaction.length > 0)

    // Invisible when the message has no reactions.
    visible: hasReactions

    // Only the height is derived from the content: propagating implicitWidth
    // back up from the Flow (which was anchored to this item) fed a size
    // cycle into the surrounding ColumnLayout.
    implicitHeight: hasReactions ? flow.implicitHeight : 0

    Flow {
        id: flow

        x: 0
        width: parent.width
        height: implicitHeight

        spacing: 8

        Repeater {
            model: reaction

            Item {
                width: Math.min(pillLabel.implicitWidth + 12, 128)
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: modelData.hasLocalUser ? PPalette.accent : PPalette.secondaryText
                    opacity: modelData.hasLocalUser ? 1.0 : 0.45
                }

                Text {
                    id: pillLabel

                    anchors.fill: parent
                    anchors.margins: 6

                    text: modelData.reaction + (modelData.count > 1 ? " " + modelData.count : "")
                    color: "white"
                    font.pointSize: 11
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: currentRoom.toggleReaction(eventId, modelData.reaction)
                }
            }
        }
    }
}
