import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import PCP.Component 2.0
import PCP.Style 0.1

import PCP 0.1

import "qrc:/js/util.js" as Util

PDrawer {
    property var room

    id: drawer

    panelWidth: 320

    ColumnLayout {
        parent: drawer.panel

        anchors.fill: parent
        anchors.margins: 32

        PItemDelegate {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            contentItem: MaterialIcon { icon: "\ue5c4" }

            onClicked: drawer.close()
        }

        ImageItem {
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96
            Layout.alignment: Qt.AlignHCenter

            hint: room ? room.displayName : "No name"
            image: pcpController.safeImage(room ? room.avatar : null)
        }

        Label {
            Layout.fillWidth: true

            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            text: room && room.id ? room.id : ""
        }

        Label {
            Layout.fillWidth: true

            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            text: room && room.canonicalAlias ? room.canonicalAlias : "No Canonical Alias"
        }

        Label {
            Layout.fillWidth: true

            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            text: room ? room.memberCount + " Members" : "No Member Count"
        }

        RowLayout {
            Layout.fillWidth: true

            AutoTextField {
                Layout.fillWidth: true

                id: roomNameField
                text: room && room.name ? room.name : ""
            }

            PItemDelegate {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48

                contentItem: MaterialIcon { icon: "\ue5ca" }

                // FORK-ONLY: power-level gate (m.room.name).
                enabled: room && room.canSendState("m.room.name")

                onClicked: room.setName(roomNameField.text)
            }
        }

        RowLayout {
            Layout.fillWidth: true

            AutoTextField {
                Layout.fillWidth: true

                id: roomTopicField

                text: room && room.topic ? room.topic : ""
            }

            PItemDelegate {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48

                contentItem: MaterialIcon { icon: "\ue5ca" }

                // FORK-ONLY: power-level gate (m.room.topic).
                enabled: room && room.canSendState("m.room.topic")

                onClicked: room.setTopic(roomTopicField.text)
            }
        }

        AutoListView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            id: userListView

            clip: true

            boundsBehavior: Flickable.DragOverBounds

            model: UserListModel {
                room: drawer.room
            }

            delegate: Column {
                property bool expanded: false

                PItemDelegate {
                    width: userListView.width
                    height: 48

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 12

                        ImageItem {
                            Layout.preferredWidth: height
                            Layout.fillHeight: true

                            image: avatar
                            hint: name
                        }

                        Label {
                            Layout.fillWidth: true

                            text: name
                        }

                        // FORK-ONLY: power-level badge ported from Jan 2020.
                        Label {
                            visible: perm !== UserType.Member

                            text: {
                                if (perm === UserType.Owner) return "Owner"
                                if (perm === UserType.Admin) return "Admin"
                                if (perm === UserType.Moderator) return "Mod"
                                if (perm === UserType.Muted) return "Muted"
                                return ""
                            }
                            color: perm === UserType.Muted ? "grey" : PPalette.accent
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

                    PButton {
                        Layout.fillWidth: true

                        text: "Kick"

                        // FORK-ONLY: only enabled when our power level
                        // allows kicking this user.
                        enabled: room && room.canKick(userId)

                        onClicked: room.kickMember(userId)
                    }

                    Behavior on height {
                        PropertyAnimation { easing.type: Easing.InOutCubic; duration: 200 }
                    }
                }
            }
        }

        PButton {
            Layout.fillWidth: true

            text: "Invite User"

            onClicked: inviteUserDialog.open()
        }
    }

    PDialog {
        parent: drawer

        id: inviteUserDialog

        title: "Input User ID"

        contentItem: AutoTextField {
            id: inviteUserDialogTextField
            placeholderText: "@bot:matrix.org"
        }

        onAccepted: room.inviteToRoom(inviteUserDialogTextField.text)
    }
}
