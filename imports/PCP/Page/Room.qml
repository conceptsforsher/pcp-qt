import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import PCP.Panel 2.0
import PCP.Component 2.0
import PCP.Effect 2.0

import PCP 0.1
import PCP.Setting 0.1

Item {
    property alias connection: roomListModel.connection
    property alias enteredRoom: roomListForm.enteredRoom
    property alias filter: roomListForm.filter

    id: page

    RoomListModel {
        id: roomListModel

        onNewMessage: if (!window.active) pcpController.postNotification(roomId, eventId, roomName, senderName, text, icon, iconPath)
    }

    SplitView {
        anchors.fill: parent

        RoomListPanel {
            // FORK-ONLY: do NOT collapse the room list to the 64px avatar
            // bar on layout. The original
            //     onWidthChanged: { if (width < 240) width = 64 }
            // is a feedback loop: SplitView's first layout pass hands the
            // panel a width of 0, that snaps it to 64, and then `64 < 240`
            // re-fires forever - so the panel stayed 64px wide, `miniMode`
            // stayed true and the room list showed nothing but avatars.
            // Give it a real width up front; users can still drag the
            // divider down to Layout.minimumWidth.
            width: Math.max(240, page.width * 0.35)
            Layout.minimumWidth: 64

            id: roomListForm

            listModel: roomListModel

            ElevationEffect {
                anchors.fill: source
                z: source.z - 1

                source: parent
                elevation: 4
            }
        }

        RoomPanel {
            Layout.fillWidth: true
            Layout.minimumWidth: 480

            id: roomForm

            currentRoom: roomListForm.enteredRoom
        }
    }

    function goToEvent(eventID) {
        roomForm.goToEvent(eventID)
    }
}
