import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2
// NOTE (Qt 5.6 port): Qt.labs.platform / Qt.labs.settings do not exist on
// Qt 5.6, so the tray icon lives in PCP.Compat.TrayIcon (loaded
// lazily, ignored when unavailable) and settings in PCP.Setting
// (LocalStorage-backed, no labs dependency). See COMPAT/Qt56.md.

import PCP.Component 2.0
import PCP.Page 2.0
import PCP.Style 0.1

import PCP 0.1
import PCP.Setting 0.1

import "qrc:/js/util.js" as Util

ApplicationWindow {
    readonly property var currentConnection: accountListView.currentConnection ? accountListView.currentConnection : null

    width: 960
    height: 640
    minimumWidth: 720
    minimumHeight: 360

    id: window

    visible: true
    title: qsTr("PCP")

    // FORK-ONLY: keep Qt's application palette in step with our own theme.
    // Controls 1 Labels default to SystemPalette.windowText, i.e. they follow
    // the *desktop's* colour scheme. On a dark-themed desktop that is white,
    // which on this app's light backgrounds means invisible text - the room
    // list rendered avatars with unreadable names. pcpApplyTheme()
    // lives in src/themepalette.h; the harness stubs it (see t_palette.qml).
    function applyAppTheme() {
        // pcpApplyTheme is a QObject (src/themepalette.h), not a
        // function: `typeof x !== "undefined"` is true for it, so the guard
        // has to check that its Q_INVOKABLE is actually reachable.
        if (typeof pcpApplyTheme !== "undefined"
                && pcpApplyTheme
                && typeof pcpApplyTheme.apply === "function")
            pcpApplyTheme.apply(PSettings.darkTheme)
    }

    Connections {
        target: PSettings
        onDarkThemeChanged: window.applyAppTheme()
    }

    // System tray (desktop only, Qt >= 5.8). On Qt 5.6 / Android this
    // Loader simply stays empty — the app remains fully usable.
    Loader {
        id: trayLoader
        active: PSettings.showTray && Qt.platform.os !== "android"
        source: "qrc:/imports/PCP/Compat/TrayIcon.qml"
        onLoaded: {
            if (item) {
                item.hideRequested.connect(hideWindow);
                item.showRequested.connect(showWindow);
                item.quitRequested.connect(Qt.quit);
            }
        }
    }

    Controller {
        id: pcpController

        quitOnLastWindowClosed: !PSettings.showTray

        onNotificationClicked: {
            roomPage.enteredRoom = currentConnection.room(roomId)
            roomPage.goToEvent(eventId)
            showWindow()
        }
        onErrorOccured: {
            errorDialog.error = error
            errorDialog.detail = detail
            errorDialog.open()
        }
    }

    AccountListModel {
        id: accountListModel
        controller: pcpController
    }

    PDialog {
        property string error
        property string detail

        id: errorDialog

        title: error + " Error"
        contentItem: Label { text: errorDialog.detail }
    }

    Component {
        id: loginPage

        Login { controller: pcpController }
    }

    Room {
        id: roomPage

        parent: null

        connection: currentConnection
    }

    Setting {
        id: settingPage

        parent: null

        listModel: accountListModel
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 64
            Layout.fillHeight: true

            id: sideNav

            color: PPalette.primary

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                AutoListView {
                    property var currentConnection: null

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    id: accountListView

                    model: accountListModel

                    spacing: 0

                    clip: true

                    delegate: Column {
                        property bool expanded: accountListView.currentConnection === connection

                        width: parent.width

                        spacing: 0

                        SideNavButton {
                            width: parent.width
                            height: width

                            selected: stackView.currentItem === page && currentConnection === connection

                            ImageItem {
                                anchors.fill: parent
                                anchors.margins: 12

                                hint: user.displayName
                                image: user.avatar
                            }

                            highlightColor: pcpController.color(user.id)

                            page: roomPage

                            onClicked: {
                                accountListView.currentConnection = connection
                                roomPage.filter = 0
                            }
                        }

                        Column {
                            width: parent.width
                            height: expanded ? implicitHeight : 0

                            spacing: 0
                            clip: true

                            SideNavButton {
                                width: parent.width
                                height: width

                                MaterialIcon {
                                    anchors.fill: parent

                                    icon: "\ue7f7"
                                    color:  "white"
                                }

                                onClicked: roomPage.filter = 1
                            }

                            SideNavButton {
                                width: parent.width
                                height: width

                                MaterialIcon {
                                    anchors.fill: parent

                                    icon: "\ue7fd"
                                    color:  "white"
                                }

                                onClicked: roomPage.filter = 2
                            }

                            SideNavButton {
                                width: parent.width
                                height: width

                                MaterialIcon {
                                    anchors.fill: parent

                                    icon: "\ue7fb"
                                    color:  "white"
                                }

                                onClicked: roomPage.filter = 3
                            }

                            Behavior on height {
                                PropertyAnimation { easing.type: Easing.InOutCubic; duration: 200 }
                            }
                        }
                    }
                }

                SideNavButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: width

                    MaterialIcon {
                        anchors.fill: parent

                        icon: "\ue145"
                        color:  "white"
                    }

                    // FORK-ONLY: no account, no rooms (C++ guards too).
                    enabled: currentConnection !== null

                    onClicked: addRoomMenu.popup()

                    Menu {
                        id: addRoomMenu

                        MenuItem {
                            text: "New Room"
                            onTriggered: addRoomDialog.open()
                        }

                        MenuItem {
                            text: "Join Room"
                            onTriggered: joinRoomDialog.open()
                        }

                        MenuItem {
                            text: "Direct Chat"
                            onTriggered: directChatDialog.open()
                        }
                    }
                }

                SideNavButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: width

                    MaterialIcon {
                        anchors.fill: parent

                        icon: "\ue8b8"
                        color: "white"
                    }
                    page: settingPage
                }

                SideNavButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: width

                    MaterialIcon {
                        anchors.fill: parent

                        icon: "\ue8ac"
                        color: "white"
                    }

                    onClicked: PSettings.confirmOnExit ? confirmExitDialog.open() : Qt.quit()
                }
            }
        }

        PScreenStack {
            Layout.fillWidth: true
            Layout.fillHeight: true

            id: stackView

            initialItem: roomPage
        }
    }

    PDialog {
        id: addRoomDialog

        title: "New Room"

        contentItem: Column {
            spacing: 8

            AutoTextField {
                width: parent.width

                id: addRoomDialogNameTextField

                placeholderText: "Name"
            }
            AutoTextField {
                width: parent.width

                id: addRoomDialogTopicTextField

                placeholderText: "Topic"
            }
        }

        onAccepted: pcpController.createRoom(currentConnection, addRoomDialogNameTextField.text, addRoomDialogTopicTextField.text)
    }

    PDialog {
        id: joinRoomDialog

        title: "Join Room"

        maxWidth: 480

        // FORK-ONLY: public room directory browser ported from Dec 2019.
        contentItem: PublicRoomBrowser {
            connection: currentConnection

            onJoinRequested: {
                pcpController.joinRoom(currentConnection, roomIdOrAlias)
                joinRoomDialog.close()
            }
        }

        onAccepted: joinRoomDialog.close()
    }

    PDialog {
        id: directChatDialog

        title: "Start Direct Chat"

        maxWidth: 480

        // FORK-ONLY: user directory browser ported from Dec 2019.
        contentItem: UserDirectoryBrowser {
            connection: currentConnection

            onChatRequested: {
                pcpController.createDirectChat(currentConnection, userId)
                directChatDialog.close()
            }
        }

        onAccepted: directChatDialog.close()
    }

    PDialog {
        id: confirmExitDialog

        title: "Exit"

        contentItem: Column {
            spacing: 8

            Label { text: "Exit?" }
            CheckBox {
                text: "Do not ask next time"
                checked: !PSettings.confirmOnExit

                onCheckedChanged: PSettings.confirmOnExit = !checked
            }
        }

        onAccepted: Qt.quit()
    }

    Binding {
        target: imageProvider
        property: "connection"
        value: currentConnection
    }

    function showWindow() {
        window.show()
        window.raise()
        window.requestActivate()
    }

    function hideWindow() {
        window.hide()
    }

    Component.onCompleted: {
        applyAppTheme()
        pcpController.initiated.connect(function() {
            if (pcpController.accountCount == 0) stackView.push(loginPage)
        })
    }
}
