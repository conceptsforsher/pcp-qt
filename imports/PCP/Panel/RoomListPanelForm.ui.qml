import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2
import QtGraphicalEffects 1.0
import QtQml.Models 2.2

import PCP.Component 2.0
import PCP.Menu 2.0
import PCP.Effect 2.0
import PCP.Style 0.1

import PCP 0.1
import PCP.Setting 0.1
import SortFilterProxyModel 0.2

import "qrc:/js/util.js" as Util

Rectangle {
    property var listModel
    property int filter: 0
    property var enteredRoom: null

    property alias searchField: searchField
    property alias model: listView.model

    property bool miniMode: width == 64

    color: PSettings.darkTheme ? "#323232" : "#f3f3f3"

    Label {
        text: miniMode ? "Empty" : "Here? No, not here."
        anchors.centerIn: parent
        visible: listView.count === 0
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.margins: 12

            color: PSettings.darkTheme ? "#303030" : "#fafafa"

            RowLayout {
                anchors.fill: parent

                spacing: 0

                MaterialIcon {
                    Layout.preferredWidth: height
                    Layout.fillHeight: true

                    visible: !miniMode && !searchField.text

                    icon: "\ue8b6"
                    color: "grey"
                }

                PItemDelegate {
                    Layout.preferredWidth: 48
                    Layout.fillHeight: true

                    visible: !miniMode && searchField.text

                    contentItem: MaterialIcon {
                        icon: "\ue5cd"
                        color: "grey"
                    }

                    onClicked: searchField.text = ""
                }

                AutoTextField {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    id: searchField

                    placeholderText: "Search..."
                }
            }
        }

        AutoListView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            id: listView

            spacing: 1
            clip: true

            boundsBehavior: Flickable.DragOverBounds

            delegate: RoomListDelegate {
                width: parent.width
                height: 64
            }

            section.property: "display"
            section.criteria: ViewSection.FullString
            section.delegate: Item {
                width: parent.width
                height: 24

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: miniMode ? 0 : 16

                    text: section
                    color: "grey"
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: miniMode ? Text.AlignHCenter : Text.AlignLeft
                }
            }

            RoomContextMenu { id: roomContextMenu }
        }
    }
}
