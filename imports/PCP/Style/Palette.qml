pragma Singleton
// SPDX-License-Identifier: GPL-3.0-only
// PCP palette — replaces QtQuick.Controls.Material (Qt >= 5.7).
//
// Colors kept from the old qtquickcontrols2.conf:
// primary #344955, accent #498882.
import QtQuick 2.6

import PCP.Setting 0.1

QtObject {
    property color primary: "#344955"
    property color accent: "#498882"

    property bool dark: PSettings.darkTheme

    property color background: dark ? "#303030" : "#fafafa"
    property color foreground: dark ? "#f5f5f5" : "#212121"
    property color card: dark ? "#424242" : "#ffffff"
    property color secondaryText: dark ? "#bdbdbd" : "#757575"
    property color inputBackground: dark ? "#242424" : "#eaeaea"
}
