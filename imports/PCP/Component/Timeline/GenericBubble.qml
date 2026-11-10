// SPDX-License-Identifier: GPL-3.0-only
// Message bubble (Qt 5.6 safe, pure QtQuick).
// Replaces the Controls 2 Control based version (padding / contentItem /
// background). contentItem is reparented into the padded holder and
// stretched to the bubble width.
import QtQuick 2.6

import PCP.Component 2.0
import PCP.Effect 2.0

import PCP.Setting 0.1
import PCP.Style 0.1

Item {
    property bool highlighted: false
    property bool colored: false

    readonly property bool darkBackground: highlighted  ? true : PSettings.darkTheme

    property int padding: 12
    property var contentItem

    id: root

    // CRITICAL (Qt 5.6 / Controls 1): a bare Item has implicitWidth and
    // implicitHeight of 0, and QtQuick.Layouts sizes a child from those.
    // The bubble therefore collapsed to 0x0, and because contentItem was
    // additionally bound to holder.width the message column got width 0 -
    // every message rendered as an empty sliver. Controls 2's Control
    // derived its implicit size from contentItem + padding; reproduce that.
    implicitWidth: contentItem ? contentItem.implicitWidth + padding * 2 : 0
    implicitHeight: contentItem ? contentItem.implicitHeight + padding * 2 : 0

    // FORK-ONLY: the content is STRETCHED to the bubble (this is what
    // Controls 2's Control did for us upstream), and the bubble gets its
    // implicit size from the content. Without the stretch the content kept
    // its own layout-driven width, and see MessageDelegate for why that
    // width was collapsing.
    onContentItemChanged: reparentContent()
    Component.onCompleted: reparentContent()

    function reparentContent() {
        if (!contentItem)
            return
        contentItem.parent = holder
        // NB: Qt.binding() takes a *function* here - the string form
        // ("holder.width") was dropped long before Qt 5.
        //
        // Only the WIDTH is stretched. Binding the height too looks
        // symmetrical but makes implicitHeight depend on itself (the bubble
        // sizes from contentItem.implicitHeight, and holder.height comes
        // back from the bubble) - Qt reports "Binding loop detected for
        // property implicitHeight" and the bubble collapses. Nothing in a
        // timeline column uses Layout.fillHeight, so the height is better
        // left to the content.
        contentItem.width = Qt.binding(function() { return holder.width })
    }

    Rectangle {
        anchors.fill: parent
        color: root.colored ? PPalette.accent : root.highlighted ? PPalette.primary : PPalette.card

        layer.enabled: true
        layer.effect: ElevationEffect {
            elevation: 1
        }
    }

    Item {
        id: holder

        x: root.padding
        y: root.padding
        width: Math.max(0, root.width - root.padding * 2)
        height: Math.max(0, root.height - root.padding * 2)
    }

    AutoMouseArea {
        anchors.fill: parent

        onSecondaryClicked: {
            messageContextMenu.row = messageRow
            messageContextMenu.model = model
            messageContextMenu.selectedText = contentLabel.selectedText
            messageContextMenu.popup()
        }
    }
}
