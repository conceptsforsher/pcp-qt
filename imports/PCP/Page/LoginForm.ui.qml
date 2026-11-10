import QtQuick 2.6
import QtQuick.Layouts 1.2
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.4

import PCP.Component 2.0
import PCP.Style 0.1

import PCP.Setting 0.1

Item {
    property var controller

    property alias loginButton: loginButton
    property alias serverField: serverField
    property alias usernameField: usernameField
    property alias passwordField: passwordField
    property alias loginError: loginErrorLabel

    Row {
        anchors.fill: parent

        Rectangle {
            width: parent.width / 2
            height: parent.height

            Image {
                id: background
                anchors.fill: parent
                source: "qrc:/assets/img/background.jpg"
                fillMode: Image.PreserveAspectCrop
                cache: false
            }

            ColorOverlay {
                anchors.fill: background
                source: background
                color: PPalette.accent
                opacity: 0.7
            }

            Column {
                x: 32
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    text: "PCP CHAT"
                    font.pointSize: 28
                    font.bold: true
                    color: "white"
                }

                Label {
                    text: "MATRIX ON OLD DEVICES"
                    font.pointSize: 12
                    color: "white"
                }
            }
        }

        Rectangle {
            width: parent.width / 2
            height: parent.height

            color: PPalette.background

            ColumnLayout {
                width: parent.width - 128
                anchors.centerIn: parent

                id: mainCol

                AutoTextField {
                    Layout.fillWidth: true

                    id: serverField

                    text: "https://matrix.org"
                    placeholderText: "Server"
                }

                AutoTextField {
                    Layout.fillWidth: true

                    id: usernameField

                    placeholderText: "Username"
                }

                AutoTextField {
                    Layout.fillWidth: true

                    id: passwordField

                    placeholderText: "Password"
                    echoMode: TextInput.Password
                }

                PButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48

                    id: loginButton

                    text: "LOGIN"
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap

                    id: loginErrorLabel

                    color: "red"
                    visible: text !== ""
                }
            }
        }
    }
}
