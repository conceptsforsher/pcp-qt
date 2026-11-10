// SPDX-License-Identifier: GPL-3.0-only
// Centered state/event label (Qt 5.6 safe, pure QtQuick).
// Replaces the Controls 2 Label based version (padding / background).
import QtQuick 2.6
import QtQuick.Layouts 1.2

import PCP.Setting 0.1

import "qrc:/js/util.js" as Util

Item {
    property alias text: label.text

    Layout.alignment: Qt.AlignHCenter

    id: root

    // FORK-ONLY: measure the text OUTSIDE the layout.
    //
    // A Text that is anchors.fill'ed to this Item and wraps cannot report the
    // width it wants: Qt lays it out at whatever width it was handed and the
    // implicit width then degenerates to the widest single word. Every state
    // event ("Bob joined the room") therefore rendered as an 8px sliver -
    // the row of small grey boxes in the timeline. TextMetrics measures at
    // its own natural width and is immune to that. The height still comes
    // from the Text because only it knows how the text wrapped.
    //
    // NB: Qt 5.6's TextMetrics has no textFormat, so measure the text with
    // the markup stripped.
    readonly property real naturalWidth: metrics.width + 16
    readonly property real widthCap:
        Layout.maximumWidth > 0 ? Layout.maximumWidth : naturalWidth

    // FORK-ONLY: restore the text binding the Qt 5.6 port dropped. Tag 464
    // was a Controls 2 Label with
    //     text: "<b>" + author.displayName + "</b> " + display
    // and replacing that Label with a bare Item + Text lost the binding
    // entirely: `text` was never set, so every state event ("joined the
    // room", "set the topic to: ...") drew as an empty grey box. Both roles
    // have to be guarded - they arrive as undefined while the model resets.
    readonly property string authorText:
        (author && author.displayName !== undefined) ? author.displayName : ""
    readonly property string displayText:
        (display != null) ? String(display) : ""

    implicitWidth: Math.min(naturalWidth, widthCap)
    implicitHeight: label.implicitHeight + 8

    TextMetrics {
        id: metrics

        font: label.font
        text: Util.stripMarkup(label.text)
    }

    Rectangle {
        anchors.fill: parent
        color: PSettings.darkTheme ? "#484848" : "grey"
    }

    Text {
        id: label

        anchors.fill: parent
        anchors.margins: 8

        text: "<b>" + root.authorText + "</b> " + root.displayText

        color: "white"
        wrapMode: Text.Wrap
        textFormat: PSettings.richText ? Text.RichText : Text.StyledText

        onLinkActivated: Qt.openUrlExternally(link)
    }
}