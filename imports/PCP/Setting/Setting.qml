pragma Singleton
// SPDX-License-Identifier: GPL-3.0-only
// PCP settings, persisted via Qt.labs.settings (available on
// Qt 5.6 and later; backed by QSettings on all platforms).
import QtQuick 2.6
import Qt.labs.settings 1.0

Settings {
    property bool pressAndHold: false
    property bool showTray: true
    property bool confirmOnExit: true

    property bool darkTheme: false
    property bool richText: true
}
