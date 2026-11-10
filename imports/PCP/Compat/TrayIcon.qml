// SPDX-License-Identifier: GPL-3.0-only
// System tray icon — desktop only (Qt >= 5.8, Qt.labs.platform).
//
// Loaded lazily from qml/main.qml via Loader. On Qt 5.6 / Android the
// module does not exist, the Loader fails silently and the app simply
// runs without a tray icon.
import QtQuick 2.6
import Qt.labs.platform 1.0 as Platform

Platform.SystemTrayIcon {
    id: tray
    visible: true
    iconSource: "qrc:/assets/img/icon.png"

    signal hideRequested()
    signal showRequested()
    signal quitRequested()

    menu: Platform.Menu {
        Platform.MenuItem {
            text: qsTr("Hide Window")
            onTriggered: tray.hideRequested()
        }
        Platform.MenuItem {
            text: qsTr("Quit")
            onTriggered: tray.quitRequested()
        }
    }

    onActivated: tray.showRequested()
}
