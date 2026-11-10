import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import PCP 0.1
import PCP.Style 0.1

Item {
    property var textArea
    property string emojiCategory: "people"

    visible: false

    function open() { visible = true }
    function close() { visible = false }

    Rectangle {
        anchors.fill: parent
        color: PPalette.card
        border.color: PPalette.secondaryText
    }

    EmojiModel {
        id: emojiModel
        category: emojiCategory
    }

    ColumnLayout {
        anchors.fill: parent

        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            cellWidth: 36
            cellHeight: 36

            boundsBehavior: Flickable.DragOverBounds

            clip: true

            model: emojiModel.model

            delegate: Text {
                width: 36
                height: 36

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                font.pointSize: 20
                font.family: "Emoji"
                text: modelData

                MouseArea {
                    anchors.fill: parent
                    onClicked: textArea.insert(textArea.cursorPosition, modelData)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 2

            color: PPalette.accent
        }

        Row {
            EmojiButton { text: "😏"; category: "people" }
            EmojiButton { text: "🌲"; category: "nature" }
            EmojiButton { text: "🍛"; category: "food"}
            EmojiButton { text: "🚁"; category: "activity" }
            EmojiButton { text: "🚅"; category: "travel" }
            EmojiButton { text: "💡"; category: "objects" }
            EmojiButton { text: "🔣"; category: "symbols" }
            EmojiButton { text: "🏁"; category: "flags" }
        }
    }
}
