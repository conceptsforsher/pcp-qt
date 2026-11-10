// SPDX-License-Identifier: GPL-3.0-only
// Single-line text field in PCP style (Qt 5.6 safe:
// Controls 1.4 + Styles 1.1). Replaces the Controls 2 based version.
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.1

import PCP.Style 0.1

TextField {
    selectByMouse: true

    style: TextFieldStyle {
        // FORK-ONLY: explicit text colors — the custom background would
        // otherwise leave typed text at the style default (unreadable
        // in one of the themes).
        textColor: PPalette.foreground
        placeholderTextColor: PPalette.secondaryText
        background: Rectangle {
            implicitHeight: 48
            color: PPalette.inputBackground
            border.color: control.activeFocus ? PPalette.accent : "transparent"
            border.width: 2
        }
        padding {
            left: 16
        }
    }
}
