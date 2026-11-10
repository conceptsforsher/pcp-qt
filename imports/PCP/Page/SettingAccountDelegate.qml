import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import PCP.Component 2.0

import PCP 0.1
import PCP.Setting 0.1

Column {
    property bool expanded: false
    // FORK-ONLY: access-token visibility + copy confirmation, for the NeoChat
    // 2fa6ad22 port below. Reset when the row is collapsed so re-opening the
    // account never comes back with the token on screen.
    property bool tokenVisible: false
    property bool copied: false

    onExpandedChanged: if (!expanded) tokenVisible = false

    spacing: 8

    PItemDelegate {
        width: accountSettingsListView.width
        height: 64

        Row {
            anchors.fill: parent
            anchors.margins: 8

            spacing: 8

            ImageItem {
                width: parent.height
                height: parent.height

                hint: user.displayName
                image: user.avatar
            }

            ColumnLayout {
                Label {
                    text: user.displayName
                }
                Label {
                    text: user.id
                }
            }
        }

        onClicked: expanded = !expanded
    }

    ColumnLayout {
        width: parent.width - 32
        height: expanded ? implicitHeight : 0
        anchors.horizontalCenter: parent.horizontalCenter

        spacing: 0

        clip: true

        AutoListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 24

            orientation: ListView.Horizontal

            spacing: 8

            model: ["#498882", "#42a5f5", "#5c6bc0", "#7e57c2", "#ab47bc", "#ff7043"]

            delegate: Rectangle {
                width: parent.height
                height: parent.height
                radius: width / 2

                color: modelData

                MouseArea {
                    anchors.fill: parent

                    onClicked: pcpController.setColor(connection.localUserId, modelData)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Homeserver:"
            }
            AutoTextField {
                Layout.fillWidth: true

                text: connection.homeserver
                readOnly: true
            }
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 16

            Label {
                text: "Device ID:"
            }
            AutoTextField {
                Layout.fillWidth: true

                text: connection.deviceId
                readOnly: true
            }
        }

        // FORK-ONLY: ported from KDE NeoChat 2fa6ad22 (2024-12-04, "Expose
        // access token under developer tools"), the only copy-token feature
        // any of the three projects ever had - upstream Spectral never had
        // one. NeoChat's wording is kept because its warning is the point:
        //   "I need this from time to time. For example, debugging an API call
        //    or scripting something with the admin API. This is buried under
        //    developer settings so hopefully no one starts sharing this
        //    willy-nilly."
        // Everything else is adapted: NeoChat binds to Quotient's
        // `connection.accessToken` and KDE's `Clipboard` singleton, neither of
        // which exists here. libQMatrixClient's Connection also has no
        // accessToken property (the token lives in the QVariant reply the
        // login job produced), so the value comes through a new
        // Q_INVOKABLE on Controller - reading `.accessToken` off the
        // connection in QML yields undefined. Clipboard goes through
        // Controller::copyToClipboard, which already exists and is
        // QML-callable; it was simply never called from anywhere.
        //
        // Masked by default, like NeoChat: a token is full account access, and
        // this delegate also renders the homeserver URL and user id, so a
        // screenshot of the settings page should not hand over the account.
        RowLayout {
            Layout.fillWidth: true

            spacing: 16

            Label {
                text: "Access Token:"
            }
            AutoTextField {
                id: accessTokenField

                Layout.fillWidth: true

                // FORK-ONLY: password echo mode, so the field is dots until
                // revealed. Qt 5.6 Controls 1 TextField supports echoMode.
                echoMode: tokenVisible ? TextInput.Normal : TextInput.Password
                readOnly: true
                selectByMouse: true

                text: {
                    var token = pcpController.accessTokenOf(connection)
                    if (token === undefined || token === null)
                        return ""
                    // NB: show the real value only when revealed, but fall back
                    // to the masked form if it is missing - printing
                    // "undefined" into a field labelled Access Token reads as a
                    // bug and hides the actual failure.
                    // NB: String.prototype.repeat does not exist in Qt 5.6's
                    // JS engine ("Property 'repeat' of object • is not a
                    // function"), so build the mask in a loop.
                    if (tokenVisible || token === "")
                        return token
                    var mask = ""
                    for (var i = 0; i < token.length; ++i)
                        mask += "•"
                    return mask
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 8

            PButton {
                text: tokenVisible ? "Hide token" : "Show token"

                onClicked: tokenVisible = !tokenVisible
            }

            PButton {
                // Copying does not require revealing it: that is the whole
                // point of the copy button, so no disabling on tokenVisible.
                text: copied ? "Copied" : "Copy token"

                onClicked: {
                    pcpController.copyToClipboard(
                        pcpController.accessTokenOf(connection))
                    copied = true
                    copyHintTimer.restart()
                }
            }

            Label {
                Layout.fillWidth: true

                // NB: this file has never referenced PPalette (it comes from
                // main.cpp, which the harness leaves out), so use a literal
                // grey rather than introducing a dependency the delegate does
                // not otherwise have.
                text: "Full account access - do not share this."
                color: "grey"
                font.pointSize: 8
                wrapMode: Text.Wrap
            }
        }

        Timer {
            id: copyHintTimer

            interval: 1500
            onTriggered: copied = false
        }

        PButton {
            Layout.fillWidth: true

            text: "Mark all as read"

            onClicked: pcpController.markAllMessagesAsRead(connection)
        }

        PButton {
            Layout.fillWidth: true

            text: "Logout"

            onClicked: pcpController.logout(connection)
        }
    }
}
