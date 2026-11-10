// SPDX-License-Identifier: GPL-3.0-only
// Side navigation button (Qt 5.6 safe).
import QtQuick 2.6
import QtQuick.Layouts 1.2

import PCP.Style 0.1

import "qrc:/js/util.js" as Util

PItemDelegate {
    property var page
    property bool selected: stackView.currentItem === page
    property color highlightColor: PPalette.accent

    Rectangle {
        width: selected ? 4 : 0
        height: parent.height

        color: highlightColor

        Behavior on width {
            PropertyAnimation { easing.type: Easing.InOutCubic; duration: 200 }
        }
    }

    onClicked: Util.pushToStack(stackView, page)
}
