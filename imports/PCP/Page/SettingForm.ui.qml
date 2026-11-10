import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import PCP.Component 2.0
import PCP.Effect 2.0
import PCP.Style 0.1

import PCP 0.1
import PCP.Setting 0.1

import "qrc:/js/util.js" as Util

Item {
    property alias listModel: accountSettingsListView.model

    property alias addAccountButton: addAccountButton

    implicitWidth: 400
    implicitHeight: 300

    Item {
        id: accountForm

        parent: null

        Item {
            anchors.fill: parent
            anchors.margins: 64

            ColumnLayout {
                anchors.fill: parent

                AutoListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    id: accountSettingsListView

                    boundsBehavior: Flickable.DragOverBounds

                    clip: true

                    delegate: SettingAccountDelegate {}
                }

                PButton {
                    Layout.fillWidth: true

                    id: addAccountButton

                    text: "Add Account"
                    flat: true
                }
            }
        }
    }

    Item {
        id: generalForm

        parent: null

        Item {
            anchors.fill: parent
            anchors.margins: 64

            Column {
                spacing: 8

                CheckBox {
                    text: "Use press and hold instead of right click"
                    checked: PSettings.pressAndHold

                    onCheckedChanged: PSettings.pressAndHold = checked
                }

                CheckBox {
                    text: "Show tray icon"
                    checked: PSettings.showTray

                    onCheckedChanged: PSettings.showTray = checked
                }

                CheckBox {
                    text: "Confirm on Exit"
                    checked: PSettings.confirmOnExit

                    onCheckedChanged: PSettings.confirmOnExit = checked
                }
            }
        }
    }

    Item {
        id: appearanceForm

        parent: null

        Item {
            anchors.fill: parent
            anchors.margins: 64

            Column {
                spacing: 8

                CheckBox {
                    text: "Dark theme"
                    checked: PSettings.darkTheme

                    onCheckedChanged: PSettings.darkTheme = checked
                }
            }
        }
    }

    Item {
        id: aboutForm

        parent: null

        Item {
            anchors.fill: parent
            anchors.margins: 64

            ColumnLayout {
                spacing: 16
                Image {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64

                    source: "qrc:/assets/img/icon.png"
                }
                Label {
                    text: "PCP, an IM client for the Matrix protocol."
                }
                Label {
                    text: "Released under GNU General Public License, version 3."
                }
                Text {
                    text: "<a href=\"https://github.com/pcp-chat/pcp-qt\">github.com/pcp-chat/pcp-qt</a>"
                    textFormat: Text.RichText
                    linkColor: PPalette.accent

                    onLinkActivated: Qt.openUrlExternally(link)
                }
            }
        }
    }

    Rectangle {
        width: 240
        height: parent.height
        z: 10

        id: settingDrawer

        color: PSettings.darkTheme ? "#323232" : "#f3f3f3"

        layer.enabled: true
        layer.effect: ElevationEffect {
            elevation: 4
        }

        Column {
            anchors.fill: parent

            PItemDelegate {
                width: parent.width
                height: 56

                id: backButton

                // FORK-ONLY: upstream Spectral/NeoChat has no way back from
                // Settings (dead end with zero accounts). See README
                // "Fork-only changes".
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    spacing: 12

                    MaterialIcon {
                        icon: "\ue5c4"
                        color: PPalette.accent
                    }

                    Label {
                        Layout.fillWidth: true

                        text: "Back"
                        font.bold: true
                    }
                }

                onClicked: stackView.pop()
            }

            Repeater {
                model: ListModel {
                    ListElement {
                        category: "Accounts"
                        form: 0
                    }
                    ListElement {
                        category: "General"
                        form: 1
                    }
                    ListElement {
                        category: "Appearance"
                        form: 2
                    }
                    ListElement {
                        category: "About"
                        form: 3
                    }
                }

                delegate: SettingCategoryDelegate {
                    // FORK-ONLY: explicit height, like backButton above.
                    // PItemDelegate is a bare Item and declares no
                    // implicitHeight, so the Column handed these rows height 0:
                    // the four categories (Accounts / General / Appearance /
                    // About) were in the tree at y=0, occupying nothing and
                    // drawing nothing. Settings opened on About - because
                    // initialItem is aboutForm - with an apparently blank
                    // drawer and no way to reach Accounts, which is where
                    // Logout and the copy-token button live. Verified in the
                    // harness: without a height they collapse, with it they do
                    // not.
                    width: parent.width
                    height: 56
                }
            }
        }
    }

    PScreenStack {
        anchors.fill: parent
        anchors.leftMargin: settingDrawer.width

        id: settingStackView

        initialItem: aboutForm
    }
}
