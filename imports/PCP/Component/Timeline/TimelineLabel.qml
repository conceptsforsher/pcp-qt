// SPDX-License-Identifier: GPL-3.0-only
// Rich text label for the timeline (Qt 5.6 safe).
// Replaces the Controls 2 Label based version (no padding/background there).
import QtQuick 2.6
import QtQuick.Layouts 1.2

import PCP.Setting 0.1
import PCP.Style 0.1

import "qrc:/js/util.js" as Util

Item {
    property alias text: label.text
    property alias font: label.font
    property color foreground: PPalette.foreground
    property bool coloredBackground: false
    property var background

    id: root

    // FORK-ONLY: measure the text OUTSIDE the layout, for the same reason as
    // StateDelegate - a Text that is anchors.fill'ed to its parent and wraps
    // reports a width of "the widest word at the width I was given", which
    // collapses to a sliver as soon as the layout hands out a narrow width.
    // That is how author names and "joined the room" lines ended up as 23px
    // stubs. TextMetrics is independent of the assigned width.
    //
    // The height keeps coming from the Text: only it knows how the text
    // wrapped once the width is fixed.
    readonly property real naturalWidth: metrics.width
    readonly property real widthCap:
        Layout.maximumWidth > 0 ? Layout.maximumWidth : naturalWidth

    implicitWidth: Math.min(naturalWidth, widthCap)
    implicitHeight: label.implicitHeight

    onBackgroundChanged: {
        if (background) {
            background.parent = root
            background.anchors.fill = root
        }
    }

    TextMetrics {
        id: metrics

        font: label.font
        text: Util.stripMarkup(label.text)
    }

    Text {
        id: label

        anchors.fill: parent

        color: root.coloredBackground ? "white" : root.foreground
        wrapMode: Text.Wrap
        linkColor: root.coloredBackground ? "white" : PPalette.accent
        textFormat: Text.RichText

        onLinkActivated: Qt.openUrlExternally(link)
    }
}