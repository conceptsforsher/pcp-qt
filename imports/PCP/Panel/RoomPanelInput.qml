import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.2

import PCP.Component 2.0
import PCP.Component.Emoji 2.0
import PCP.Effect 2.0
import PCP.Setting 0.1
import PCP.Style 0.1

import PCP 0.1

import "qrc:/js/md.js" as Markdown

Rectangle {
    property bool isReply
    property string replyUserID
    property string replyEventID
    property string replyContent

    property bool isAutoCompleting
    property var autoCompleteModel
    property int autoCompleteBeginPosition
    property int autoCompleteEndPosition

    color: PSettings.darkTheme ? "#303030" : "#fafafa"

    layer.enabled: true
    layer.effect: ElevationEffect {
        elevation: 2
    }

    Label {
        anchors.bottom: parent.top
        anchors.left: parent.left
        anchors.margins: 8

        visible: currentRoom && currentRoom.hasUsersTyping
        text: currentRoom ? currentRoom.usersTyping : ""
        color: PPalette.secondaryText
        font.pointSize: 8
    }

    Item {
        x: 0
        y: -height - 10
        width: Math.min(userAutoCompleteListView.contentWidth, parent.width)
        height: 36

        id: userAutoComplete

        visible: isAutoCompleting && autoCompleteModel.length !== 0

        Rectangle {
            anchors.fill: parent
            color: PPalette.card
            border.color: PPalette.secondaryText
        }

        ListView {
            id: userAutoCompleteListView

            anchors.fill: parent

            model: autoCompleteModel

            clip: true

            orientation: ListView.Horizontal

            highlightFollowsCurrentItem: true

            highlight: Rectangle {
                color: PPalette.accent
                opacity: 0.4
            }

            delegate: PItemDelegate {
                property string displayName: modelData.displayName

                height: parent.height
                width: 160

                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 8
                    ImageItem {
                        width: parent.height
                        height: parent.height
                        image: modelData.avatar
                    }
                    Label {
                        height: parent.height
                        text: modelData.displayName
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onClicked: {
                    userAutoCompleteListView.currentIndex = index
                    inputField.replaceAutoComplete(displayName)
                }
            }
        }
    }

    Rectangle {
        width: currentRoom && currentRoom.hasFileUploading ? parent.width * currentRoom.fileUploadingProgress / 100 : 0
        height: parent.height

        opacity: 0.2
        color: PPalette.accent
    }

    RowLayout {
        anchors.fill: parent

        spacing: 0

        PItemDelegate {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48

            id: uploadButton
            visible: !isReply

            contentItem: MaterialIcon {
                icon: "\ue226"
            }

            onClicked: currentRoom.chooseAndUploadFile()

            BusyIndicator {
                anchors.fill: parent

                running: currentRoom && currentRoom.hasFileUploading
            }
        }

        PItemDelegate {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48

            id: cancelReplyButton
            visible: isReply

            contentItem: MaterialIcon {
                icon: "\ue5cd"
            }

            onClicked: clearReply()
        }

        // FORK-ONLY: no ScrollView around this.
        //
        // A Controls 1 ScrollView does NOT stretch its content: it parents a
        // non-Flickable content item into a Flickable and leaves it at its own
        // size (ScrollView's own implicit size is 240x150, which is exactly
        // the size the field ended up). Controls 2's ScrollView does resize
        // the content, which is why upstream never noticed - the field
        // rendered as a small box hugging the left of the bar.
        //
        // The ScrollView bought nothing anyway: the bar is pinned to 48px, so
        // there was never anything to scroll. A TextArea scrolls its own
        // content when the text is longer than that.
        TextArea {
                    property real progress: 0

                    id: inputField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 48

                    wrapMode: Text.Wrap
                    selectByMouse: true

                    verticalAlignment: TextEdit.AlignVCenter

                    text: currentRoom ? currentRoom.cachedInput : ""

                    // FORK-ONLY: Qt 5.6 foot-guns in this one control.
                    // A Controls 1 TextArea has NO `background`, `color`,
                    // `selectionColor` or `selectedTextColor` property (those
                    // are Controls 2): it has `backgroundVisible` and
                    // `textColor`. It fills itself with SystemPalette.base, so
                    // on a desktop with a dark colour scheme the input
                    // rendered as an opaque black box - and `frameVisible:
                    // false`, which the port had instead, only hides the
                    // border, not the fill.
                    backgroundVisible: false
                    textColor: PPalette.foreground

                    // Qt 5.6 TextArea has no padding properties either, so the
                    // inset is done with anchors on the placeholder.
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 8

                        text: isReply ? "Reply to " + replyUserID
                                      : "Send a Message"
                        color: PPalette.secondaryText
                        verticalAlignment: Text.AlignVCenter

                        visible: inputField.text === ""
                                 && !inputField.activeFocus
                    }

                Timer {
                    id: timeoutTimer

                    repeat: false
                    interval: 2000
                    onTriggered: {
                        repeatTimer.stop()
                        if (currentRoom) currentRoom.sendTypingNotification(false)
                    }
                }

                Timer {
                    id: repeatTimer

                    repeat: true
                    interval: 5000
                    onTriggered: { if (currentRoom) currentRoom.sendTypingNotification(true) }
                }

                Keys.onReturnPressed: {
                    if (event.modifiers & Qt.ShiftModifier) {
                        insert(cursorPosition, "\n")
                    } else {
                        postMessage(text)
                        text = ""
                    }
                }

                Keys.onBacktabPressed: {
                    if (isAutoCompleting) {
                        if (userAutoCompleteListView.currentIndex == 0) userAutoCompleteListView.currentIndex = userAutoCompleteListView.count - 1
                        else userAutoCompleteListView.currentIndex--
                    }
                }

                Keys.onTabPressed: {
                    if (isAutoCompleting) {
                        if (userAutoCompleteListView.currentIndex + 1 == userAutoCompleteListView.count) userAutoCompleteListView.currentIndex = 0
                        else userAutoCompleteListView.currentIndex++
                    } else {
                        autoCompleteBeginPosition = text.substring(0, cursorPosition).lastIndexOf(" ") + 1
                        var autoCompletePrefix = text.substring(0, cursorPosition).split(" ").pop()
                        if (!autoCompletePrefix) return
                        autoCompleteModel = currentRoom.getUsers(autoCompletePrefix)
                        if (autoCompleteModel.length === 0) return
                        isAutoCompleting = true
                        autoCompleteEndPosition = cursorPosition
                    }

                    replaceAutoComplete(userAutoCompleteListView.currentItem.displayName)
                }

                onTextChanged: {
                    timeoutTimer.restart()
                    if (currentRoom && !repeatTimer.running)
                        currentRoom.sendTypingNotification(true)
                    repeatTimer.start()
                    if (currentRoom)
                        currentRoom.cachedInput = text

                    if (cursorPosition !== autoCompleteBeginPosition && cursorPosition !== autoCompleteEndPosition) {
                        isAutoCompleting = false
                        userAutoCompleteListView.currentIndex = 0
                    }
                }

                function replaceAutoComplete(word) {
                    remove(autoCompleteBeginPosition, autoCompleteEndPosition)
                    autoCompleteEndPosition = autoCompleteBeginPosition + word.length
                    insert(cursorPosition, word)
                }

                function postMessage(text) {
                    if (text.trim().length === 0) { return }
                    if(!currentRoom) { return }

                    var PREFIX_ME = '/me '
                    var PREFIX_NOTICE = '/notice '
                    var PREFIX_RAINBOW = '/rainbow '
                    var PREFIX_HTML = '/html '
                    var PREFIX_MARKDOWN = '/md '

                    if (isReply) {
                        currentRoom.sendReply(replyUserID, replyEventID, replyContent, text)
                        clearReply()
                        return
                    }

                    if (text.indexOf(PREFIX_ME) === 0) {
                        text = text.substr(PREFIX_ME.length)
                        currentRoom.postMessage(text, RoomMessageEvent.Emote)
                        return
                    }
                    if (text.indexOf(PREFIX_NOTICE) === 0) {
                        text = text.substr(PREFIX_NOTICE.length)
                        currentRoom.postMessage(text, RoomMessageEvent.Notice)
                        return
                    }
                    if (text.indexOf(PREFIX_RAINBOW) === 0) {
                        text = text.substr(PREFIX_RAINBOW.length)

                        var parsedText = ""
                        var rainbowColor = ["#ff2b00", "#ff5500", "#ff8000", "#ffaa00", "#ffd500", "#ffff00", "#d4ff00", "#aaff00", "#80ff00", "#55ff00", "#2bff00", "#00ff00", "#00ff2b", "#00ff55", "#00ff80", "#00ffaa", "#00ffd5", "#00ffff", "#00d4ff", "#00aaff", "#007fff", "#0055ff", "#002bff", "#0000ff", "#2a00ff", "#5500ff", "#7f00ff", "#aa00ff", "#d400ff", "#ff00ff", "#ff00d4", "#ff00aa", "#ff0080", "#ff0055", "#ff002b", "#ff0000"]
                        for (var i = 0; i < text.length; i++) {
                            parsedText = parsedText + "<font color='" + rainbowColor[i % rainbowColor.length] + "'>" + text.charAt(i) + "</font>"
                        }
                        currentRoom.postHtmlMessage(text, parsedText, RoomMessageEvent.Text)
                        return
                    }
                    if (text.indexOf(PREFIX_HTML) === 0) {
                        text = text.substr(PREFIX_HTML.length)
                        var re = new RegExp("<.*?>")
                        var plainText = text.replace(re, "")
                        currentRoom.postHtmlMessage(plainText, text, RoomMessageEvent.Text)
                        return
                    }
                    if (text.indexOf(PREFIX_MARKDOWN) === 0) {
                        text = text.substr(PREFIX_MARKDOWN.length)
                        var parsedText = Markdown.markdown_parser(text)
                        currentRoom.postHtmlMessage(text, parsedText, RoomMessageEvent.Text)
                        return
                    }

                    currentRoom.postPlainText(text)
                }
        }

        PItemDelegate {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48

            id: emojiButton

            contentItem: MaterialIcon {
                icon: "\ue24e"
            }

            onClicked: emojiPicker.visible ? emojiPicker.close() : emojiPicker.open()

            EmojiPicker {
                x: -width + parent.width
                y: -height - 16

                width: 360
                height: 320

                id: emojiPicker

                textArea: inputField
            }
        }
    }

    function insert(str) {
        inputField.insert(inputField.cursorPosition, str)
    }

    function clear() {
        inputField.clear()
    }

    function clearReply() {
        isReply = false
        replyUserID = ""
        replyEventID = ""
        replyContent = ""
    }
}
