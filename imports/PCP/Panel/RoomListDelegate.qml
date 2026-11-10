import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import PCP 0.1
import PCP.Setting 0.1
import PCP.Style 0.1

import PCP.Component 2.0

Rectangle {
    color: PSettings.darkTheme ? "#303030" : "#fafafa"

    AutoMouseArea {
        anchors.fill: parent

        hoverEnabled: miniMode

        onSecondaryClicked: {
            roomContextMenu.model = model
            roomContextMenu.popup()
        }
        onPrimaryClicked: {
            if (category === RoomType.Invited) {
                inviteDialog.currentRoom = currentRoom
                inviteDialog.open()
            } else {
                enteredRoom = currentRoom
            }
        }
    }

    Rectangle {
        anchors.fill: parent

        visible: highlightCount > 0 || currentRoom === enteredRoom
        color: PPalette.accent
        opacity: 0.1
    }

    Rectangle {
        width: unreadCount > 0 ? 4 : 0
        height: parent.height

        color: PPalette.accent

        Behavior on width {
            PropertyAnimation { easing.type: Easing.InOutCubic; duration: 200 }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12

        spacing: 12

        ImageItem {
            id: imageItem

            Layout.preferredWidth: height
            Layout.fillHeight: true

            hint: name || "No Name"

            image: avatar
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter

            visible: parent.width > 64

            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true

                text: name || "No Name"
                font.pointSize: 12
                // FORK-ONLY: upstream got the primary/secondary hierarchy
                // from Material. Now that the application palette follows our
                // own theme, both lines would come out the same colour and the
                // same size, so spell the difference out.
                color: PPalette.foreground
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }

            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true

                text: (lastEvent == "" ? topic : lastEvent).replace(/(\r\n\t|\n|\r\t)/gm,"")
                color: PPalette.secondaryText
                font.pointSize: 9
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }
        }
    }
}
