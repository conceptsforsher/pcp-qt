import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import PCP.Component 2.0
import PCP.Component.Emoji 2.0
import PCP.Component.Timeline 2.0
import PCP.Menu 2.0
import PCP.Effect 2.0
import PCP.Style 0.1

import PCP 0.1
import PCP.Setting 0.1
import SortFilterProxyModel 0.2

import "qrc:/js/md.js" as Markdown
import "qrc:/js/util.js" as Util

Item {
    property var currentRoom: null

    property alias roomHeader: roomHeader
    property alias messageListView: messageListView
    property alias goTopFab: goTopFab
    property alias goBottomFab: goBottomFab
    property alias messageEventModel: messageEventModel
    property alias sortedMessageEventModel: sortedMessageEventModel
    property alias roomDrawer: roomDrawer

    id: root

    MessageEventModel {
        id: messageEventModel
        room: currentRoom
    }

    RoomDrawer {
        id: roomDrawer

        panelWidth: Math.min(root.width * 0.7, 480)

        room: currentRoom
    }

    Label {
        anchors.centerIn: parent
        visible: !currentRoom
        text: "Please choose a room."
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        visible: currentRoom

        RoomHeader {
            Layout.fillWidth: true
            // FORK-ONLY: was a hardcoded 64. The header now reports the
            // height its content needs (RoomHeader.implicitHeight), so a
            // taller fallback font cannot clip the topic line.
            Layout.preferredHeight: implicitHeight
            z: 10

            id: roomHeader
        }

        AutoListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16

            id: messageListView

            displayMarginBeginning: 40
            displayMarginEnd: 40
            verticalLayoutDirection: ListView.BottomToTop
            spacing: 8

            boundsBehavior: Flickable.DragOverBounds

            model: SortFilterProxyModel {
                id: sortedMessageEventModel

                sourceModel: messageEventModel

                filters: ExpressionFilter {
                    expression: marks !== 0x08 && marks !== 0x10
                }
            }

            delegate: ColumnLayout {
                id: delegateColumn

                spacing: 8

                // FORK-ONLY: collapse the administrative state events a room is
                // created with - m.room.create, power_levels, join_rules,
                // history_visibility, guest_access - which libQMatrixClient 2019
                // has no typed class for. They used to reach
                // utils::eventToString's trailing fallback and draw five grey
                // "Unknown Event" bubbles at the top of every new room.
                //
                // Collapsed here rather than filtered out of MessageEventModel
                // on purpose: that model indexes the timeline by row offset in
                // data(), and its AboveXxx roles loop over rowCount(), so
                // dropping rows would mean renumbering both. A zero-height,
                // invisible delegate takes no space and needs no renumbering.
                // `eventResolvedType` is the raw m.* type from the model.
                visible: !hiddenStateRow
                height: hiddenStateRow ? 0 : implicitHeight

                readonly property bool hiddenStateRow:
                    eventType === "state" && Util.administrativeState(eventResolvedType)

                // FORK-ONLY: `section` / `display` are model roles. They must
                // NOT be redeclared here - a QML declaration shadows the
                // role on Qt 5.6 and the value would never arrive. Instead
                // coerce at the point of use (see below).

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter

                    visible: section !== aboveSection

                    width: sectionLabel.width + 16
                    height: sectionLabel.height + 8
                    radius: 2

                    color: PSettings.darkTheme ? "#484848" : "grey"

                    Label {
                        id: sectionLabel

                        anchors.centerIn: parent

                        text: section !== undefined ? section : ""
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MessageDelegate {
                    visible: eventType === "notice" || eventType === "message"
                             || eventType === "image" || eventType === "video"
                             || eventType === "audio" || eventType === "file"
                }

                StateDelegate {
                    Layout.maximumWidth: messageListView.width * 0.8

                    visible: eventType === "emote" || eventType === "state"
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter

                    visible: eventType === "other"

                    text: display !== undefined ? display : ""
                    color: "grey"
                    font.italic: true
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter

                    visible: readMarker === true && index !== 0

                    width: readMarkerLabel.width + 16
                    height: readMarkerLabel.height + 8
                    radius: 2

                    color: PSettings.darkTheme ? "#484848" : "grey"

                    Label {
                        id: readMarkerLabel

                        anchors.centerIn: parent

                        text: "And Now"
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            PCircleButton {
                width: 64
                height: 64
                anchors.right: parent.right
                anchors.top: parent.top

                id: goBottomFab

                visible: currentRoom && currentRoom.hasUnreadMessages

                icon: "\ue316"
            }

            PCircleButton {
                width: 64
                height: 64
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                id: goTopFab

                visible: !messageListView.atYEnd

                icon: "\ue313"
            }

            MessageContextMenu {
                id: messageContextMenu
            }

            PDialog {
                property string sourceText

                id: sourceDialog

                maxWidth: 480
                showButtons: false

                contentItem: ScrollView {
                    height: 300

                    TextArea {
                        id: sourceTextView

                        readOnly: true
                        selectByMouse: true

                        text: sourceDialog.sourceText
                    }
                }
            }

            PDialog {
                property alias listModel: readMarkerListView.model

                id: readMarkerDialog

                maxWidth: 320
                showButtons: false

                contentItem: AutoListView {
                    height: Math.min(400, readMarkerListView.contentHeight)

                    id: readMarkerListView

                    clip: true
                    boundsBehavior: Flickable.DragOverBounds

                    delegate: PItemDelegate {
                        width: parent.width
                        height: 48

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            ImageItem {
                                Layout.preferredWidth: height
                                Layout.fillHeight: true

                                image: modelData.avatar
                                hint: modelData.displayName
                            }

                            Label {
                                Layout.fillWidth: true

                                text: modelData.displayName
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
        }

        Rectangle {
            Layout.fillWidth: true
            // FORK-ONLY: was `Layout.preferredHeight: 40` for a 48px input
            // anchored `anchors.verticalCenter: parent.top`, i.e. centred on
            // the box's *top edge*: the input reached 24px above its box and
            // left 16px of empty bar-coloured strip below it (measured with
            // t_inputbar.qml - it is the stray strip under the input in the
            // preview21 screenshot). The 40px Item above is deliberate: it is
            // the space RoomPanelInput's "users typing" label draws into.
            Layout.preferredHeight: 48
            Layout.leftMargin: 16
            Layout.rightMargin: 16

            color: PPalette.background

            RoomPanelInput {
                anchors.fill: parent

                id: roomPanelInput
            }
        }
    }
}
