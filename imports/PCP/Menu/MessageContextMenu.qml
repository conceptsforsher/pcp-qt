import QtQuick 2.6
import QtQuick.Controls 1.4

import PCP.Component 2.0

Menu {
    property var row: null
    property var model: null
    property string selectedText

    readonly property bool isFile: model  && (model.eventType === "video" || model.eventType === "audio" || model.eventType === "file" || model.eventType === "image")

    id: messageContextMenu

    // FORK-ONLY: quick reactions ported from Jul 2019 (PItemDelegate
    // instead of ItemDelegate for Qt 5.6).
    Row {
        spacing: 0

        Repeater {
            model: ["👍", "👎", "😄", "🎉", "🚀", "👀"]

            PItemDelegate {
                width: 36
                height: 36

                text: modelData

                onClicked: currentRoom.toggleReaction(model.eventId, modelData)
            }
        }
    }

    MenuSeparator {}

    MenuItem {
        text: "View Source"

        onTriggered: {
            sourceDialog.sourceText = model.toolTip
            sourceDialog.open()
        }
    }
    MenuItem {
        visible: isFile
        text: "Open Externally"

        onTriggered: row.openExternally()
    }
    MenuItem {
        visible: isFile
        text: "Save As"

        onTriggered: row.saveFileAs()
    }
    MenuItem {
        text: "Reply"

        onTriggered: {
            roomPanelInput.isReply = true
            roomPanelInput.replyUserID = model && model.author ? model.author.id : ""
            roomPanelInput.replyEventID = model.eventId
            roomPanelInput.replyContent = selectedText != "" ? selectedText : model.message
        }
    }
    MenuItem {
        visible: model !== null && model !== undefined && model.author !== null
                && model.author !== undefined && currentRoom !== null
                && model.author === currentRoom.localUser
        text: "Redact"

        onTriggered: currentRoom.redactEvent(model.eventId)
    }
}
