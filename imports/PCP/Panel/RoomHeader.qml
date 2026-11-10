import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.2

import PCP.Component 2.0
import PCP.Style 0.1

import PCP 0.1

Rectangle {
    property alias image: headerImage.image
    property alias topic: headerTopicLabel.text
    signal clicked()

    id: header

    color: PPalette.accent

    // FORK-ONLY: size the header from what it actually contains instead of a
    // fixed 64px band. RoomPanelForm used to hardcode 64, which is exactly
    // 12 + 17.5 + 6 + 17.5 + 12 for the default font - so the moment the font
    // on the machine was a little taller (this app falls back to a different
    // font when material.ttf fails to load) the topic line was clipped. With
    // implicitHeight the header grows with its content instead.
    implicitHeight: headerRow.implicitHeight + 24

    PItemDelegate {
        anchors.fill: parent

        id: roomHeader

        onClicked: header.clicked()

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12

            spacing: 12

            id: headerRow

            ImageItem {
                // FORK-ONLY: a fixed size, not `preferredWidth: height`.
                // That was a binding cycle once the header sized itself from
                // its content: the avatar's preferred width depended on its
                // height, which depended on the row, which depended on the
                // header - and the header collapsed to 24px. 40px is what the
                // old fixed 64px band produced anyway (64 - 2*12 margins).
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                id: headerImage

                hint: currentRoom ? currentRoom.displayName : "No name"
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: parent.width > 64

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    text: currentRoom ? currentRoom.displayName : ""
                    color: "white"
                    font.pointSize: 12
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    id: headerTopicLabel

                    color: "white"
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
            }
        }
    }

    ProgressBar {
        width: parent.width
        height: 3
        z: 10
        // FORK-ONLY: at the TOP edge, not the bottom. Anchored to the bottom it
        // was 17px tall and sat on top of the topic line - which is why the
        // topic looked cut in half whenever the room was busy applying a name
        // or topic change (measured: bar y=47..64, topic bottom 52.5).
        anchors.top: parent.top

        visible: currentRoom && currentRoom.busy
        indeterminate: true

        style: ProgressBarStyle {
            background: Rectangle { color: "transparent" }
            progress: Rectangle { color: "white" }
        }
    }
}
