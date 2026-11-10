import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import PCP 0.1
import PCP.Setting 0.1
import PCP.Style 0.1

import PCP.Component 2.0

import "qrc:/js/util.js" as Util

RowLayout {
    // FORK-ONLY: do NOT declare properties named after model roles here
    // (display, author, section, marks, ...). A QML property declaration
    // SHADOWS the delegate role of the same name on Qt 5.6: verified in the
    // harness - with `property string display: ""` the DisplayRole never
    // arrives and every message renders as an empty bubble. Roles that are
    // present simply arrive as undefined, so guard at each use instead
    // (authorName, replyVisible, !!(...) below).
    readonly property bool avatarVisible:
        !sentByMe && (aboveAuthor !== author || aboveSection !== section
                      || aboveEventType === "state" || aboveEventType === "emote"
                      || aboveEventType === "other")
    readonly property bool highlighted: !(sentByMe || eventType === "notice")
    readonly property bool sentByMe:
        currentRoom != null && authorOrNull != null
        && authorOrNull === currentRoom.localUser
    readonly property bool isText: eventType === "notice" || eventType === "message"
    // FORK-ONLY: failed-message resend/discard ported from Aug 2019.
    // 0x05 == EventStatus.SendingFailed (hex literal like RoomPanelForm,
    // so the headless harness needs no C++ type registration).
    readonly property bool failed: marks === 0x05
    // `author` and `userMarker` are model roles: they arrive as undefined
    // while the model resets. Normalise each once here so that no use site
    // has to remember it - guarding only against null (as I first did) still
    // threw "Cannot read property 'avatar' of undefined".
    // NB: `x !== null` is TRUE for undefined, so these guards must use
    // truthiness (or loose !=) - otherwise the normaliser itself yields
    // undefined and every downstream `.avatar` throws.
    readonly property var authorOrNull: author != null ? author : null
    readonly property string authorName:
        (authorOrNull && authorOrNull.displayName != null)
        ? authorOrNull.displayName : ""
    // null is acceptable for ImageItem.image (a QVariant property).
    readonly property var authorAvatar:
        (authorOrNull && authorOrNull.avatar !== undefined)
        ? authorOrNull.avatar : null
    readonly property var userMarkers: userMarker != null ? userMarker : []
    readonly property bool replyVisible:
        !!(reply && reply.eventId != null && reply.eventId !== "")
    // FORK-ONLY: whether the marker/timestamp row has anything to show. Kept
    // beside replyVisible so the Row below can hide itself when it does not -
    // see the comment on that Row. `index` is a model role, hence the
    // `index === undefined` guard: while the model resets it arrives as
    // undefined and `Math.abs` would produce NaN.
    readonly property bool timeVisible:
        index !== undefined
        && (Math.abs(time - aboveTime) > 600000 || index == 0)
    readonly property bool markerRowVisible:
        timeVisible || userMarkers.length > 0
    // FORK-ONLY: one-line census of the content column's children: each
    // visible child's type and the height it contributes. Used only by the
    // diagnostic below, but kept as a function so both read the same way.
    function childHeights() {
        var parts = []
        var kids = messageColumn.children
        for (var i = 0; i < kids.length; ++i) {
            var c = kids[i]
            if (!c.visible) continue
            var h = c.implicitHeight
            if (h === undefined || h === null) h = c.height
            parts.push(i + ":" + c.toString().split("_QML")[0] + "=" + h)
        }
        return parts.join(",")
    }

    signal saveFileAs()
    signal openExternally()

    // FORK-ONLY: measure the message text *outside* the layout.
    //
    // A Label/TextEdit that is stretched by its parent and wraps cannot also
    // report how wide it wants to be: Qt lays the document out at the width
    // it has been given, and the implicit width then degenerates to the
    // widest single word. TimelineLabel has exactly that shape (an Item whose
    // implicitWidth is the anchored Text's, so authorLabel.font.family and
    // every author name collapse too), and MessageDelegate's contentLabel is
    // `Layout.fillWidth`. The result was self-fulfilling: the layout handed
    // out a provisional narrow width, the wrapped text measured 23px, and
    // the bubble stayed 23px wide forever - empty grey slivers.
    //
    // TextMetrics measures at its own natural width, so it is immune to that
    // cycle; genericBubble.implicitWidth below uses it instead of the
    // children's implicit width. Qt 5.6's TextMetrics has no textFormat, so
    // measure the markup-stripped text.
    readonly property string plainDisplay:
        (display != null) ? Util.stripMarkup(display) : ""
    readonly property int measuredTextWidth:
        (isText && plainDisplay.length > 0) ? displayMetrics.width : 0

    TextMetrics {
        id: displayMetrics

        font: contentLabel.font
        text: messageRow.plainDisplay
    }

    // FORK-ONLY: bounded diagnostic, reported *after* the layout has
    // settled. Reading geometry in Component.onCompleted is misleading -
    // implicit widths are not final yet, which made the first report look
    // like the text measured 30px wide when it does not.
    property int debugLoggedCount: 0

    Timer {
        id: debugTimer
        interval: 700
        running: true
        repeat: false

        onTriggered: {
            // FORK-ONLY: RoomPanelForm instantiates MessageDelegate,
            // StateDelegate and the "other" delegate for EVERY row and hides
            // two of them (visible: eventType === ...). A hidden instance is
            // still alive and its timer still fires, so a state row used to
            // report measured=0 and a 24x24 bubble - which says nothing about
            // how that row renders, because StateDelegate is what draws it.
            if (!messageRow.visible)
                return
            if (typeof pcpDebugDelegate !== "undefined"
                    && !pcpDebugDelegate && debugLoggedCount >= 3)
                return
            debugLoggedCount = debugLoggedCount + 1
            console.warn("DELEGATE-GEO eventType=[" + eventType + "]"
                         + " author=[" + authorName + "]"
                         + " sentByMe=" + sentByMe
                         + " avatarVisible=" + avatarVisible
                         + " displayLen=" + (display != null ? display.length : -1)
                         + " plainLen=" + messageRow.plainDisplay.length
                         + " measured=" + messageRow.measuredTextWidth
                         + " column.implicitWidth=" + messageColumn.implicitWidth
                         + " column.implicitHeight=" + messageColumn.implicitHeight
                         // FORK-ONLY: which child of the column is actually
                         // supplying the height. The column's own total was
                         // never enough to localise the gap: label 18 vs
                         // column 50 leaves 32px that no single reported number
                         // accounted for, and the harness cannot reproduce it
                         // (no fonts -> it measures 16 where the device
                         // measures 18). So report every child's contribution
                         // directly. Cheap, one line, and it names the culprit
                         // instead of leaving it to be guessed at again.
                         + " kids=[" + childHeights() + "]"
                         // Why the marker row is showing. preview28 reported
                         // kids=[...,4:QQuickRow=32] on rows that have no
                         // timestamp, i.e. the row- hides-itself fix was not
                         // holding on the device. timeVisible is only half the
                         // condition - the other half is read markers, and
                         // userMarkers.length was the untested half.
                         + " timeVisible=" + timeVisible
                         + " index=" + index
                         + " gapSec=" + (time !== undefined && aboveTime !== undefined
                                         ? Math.round(Math.abs(time - aboveTime) / 1000)
                                         : "n/a")
                         + " markers=" + userMarkers.length
                         + " label.width=" + contentLabel.width
                         + " label.implicitWidth=" + contentLabel.implicitWidth
                         + " label.implicitHeight=" + contentLabel.implicitHeight
                         + " bubble.width=" + genericBubble.width
                         + " bubble.implicitWidth=" + genericBubble.implicitWidth
                         + " bubble.implicitHeight=" + genericBubble.implicitHeight
                         + " row.implicitWidth=" + messageRow.implicitWidth
                         + " row.implicitHeight=" + messageRow.implicitHeight
                         + "\n    plain=[" + messageRow.plainDisplay.substr(0, 70) + "]"
                         // NB: do NOT log contentLabel.text here. With
                         // textFormat: RichText, Qt 5.6's TextEdit.text getter
                         // returns QTextDocument::toHtml() - a serialised
                         // document starting with `<!DOCTYPE HTML PUBLIC ...`,
                         // 456 characters for the 10-character message
                         // "mostly yes" (verified in the qmltest harness).
                         // `display` is the model role, a plain string, and is
                         // what the label was assigned.
                         + "\n    display=[" + (display != null
                                                ? display.substr(0, 70) : "") + "]")
        }
    }

    z: -5

    id: messageRow

    Layout.alignment: sentByMe ? Qt.AlignRight : Qt.AlignLeft

    spacing: 6

    ImageItem {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        Layout.alignment: Qt.AlignTop

        round: false
        visible: avatarVisible
        hint: authorName
        image: authorAvatar
    }

    Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        Layout.alignment: Qt.AlignTop

        color: "transparent"
        visible: !(sentByMe || avatarVisible)
    }

    GenericBubble {
        Layout.maximumWidth: messageListView.width - (!sentByMe ? 40 + messageRow.spacing : 0)

        id: genericBubble

        highlighted: messageRow.highlighted
        colored: !!(highlighted && (eventType === "notice" || highlight === true))

        // FORK-ONLY: size the bubble from our own measurement of the text,
        // not from contentItem.implicitWidth (see plainDisplay above). The
        // column's implicit width is still taken into account so that wide
        // non-text children - a file name, a reactions row - keep the bubble
        // from clipping them.
        implicitWidth: Math.max(messageColumn.implicitWidth,
                                messageRow.measuredTextWidth)
                       + padding * 2

        contentItem: ColumnLayout {
            id: messageColumn

            spacing: 0

            TimelineLabel {
                Layout.fillWidth: true

                id: authorLabel

                visible: messageRow.avatarVisible
                text: authorName
                foreground: PPalette.accent
                coloredBackground: highlighted
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: roomPanelInput.insert(authorName)
                }
            }

            // FORK-ONLY: reply preview ported from Jul 2019 (click jumps
            // to the replied-to event).
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: replyRow.implicitHeight + 6

                visible: messageRow.replyVisible

                id: replyPreview

                Row {
                    id: replyRow

                    anchors.fill: parent
                    anchors.leftMargin: 4

                    spacing: 6

                    Rectangle {
                        width: 3
                        height: parent.height

                        color: PPalette.accent
                    }

                    TimelineLabel {
                        width: parent.width - 9

                        text: messageRow.replyVisible
                              ? "In reply to "
                                + (reply.author ? reply.author.displayName : "")
                                + ": " + reply.display
                              : ""
                        coloredBackground: highlighted
                        foreground: "grey"
                        font.pointSize: 8
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var idx = messageEventModel.eventIDToIndex(reply.eventId)
                        if (idx >= 0)
                            messageListView.positionViewAtIndex(idx, ListView.Center)
                    }
                }
            }

            TextEdit {
                Layout.fillWidth: true

                id: contentLabel
                text: (highlighted  ? "<style>a{color: white;} .user-pill{color: white}</style>" : "<style>a{color: " + PPalette.accent + ";} .user-pill{color: " + PPalette.accent + "}</style>") + display

                visible: isText
                color: highlighted ? "white" : PPalette.foreground

                font.family: authorLabel.font.family
                font.pointSize: 10
                selectByMouse: true
                readOnly: true
                wrapMode: Text.Wrap
                selectedTextColor: highlighted ? PPalette.accent : "white"
                selectionColor: highlighted ? "white" : PPalette.accent
                textFormat: Text.RichText

                onLinkActivated: Qt.openUrlExternally(link)

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }

            Loader {
                sourceComponent: {
                    switch (eventType) {
                    case "image":
                        return imageComponent
                    case "video":
                    case "file":
                        return fileComponent
                    case "audio":
                        return audioComponent
                    }
                }

                active: eventType === "image" || eventType === "video" || eventType === "file" || eventType === "audio"
            }

            // FORK-ONLY: the marker/timestamp row hides itself when it has
            // nothing to show. A Row's own `visible` defaults to true and only
            // the labels INSIDE it were conditional, so the row kept reserving
            // its height in every bubble with no timestamp - 13px of empty band
            // under each message, which is why a one-line "test" reported
            // bubble.implicitHeight=74 for an 18px label. Row is a positioner,
            // not a layout: it sizes to its children and does not skip
            // invisible ones, so the row itself has to be hidden.
            Row {
                visible: messageRow.markerRowVisible

                Layout.alignment: Qt.AlignRight

                spacing: 4

                TimelineLabel {
                    visible: userMarkers.length > 5
                    text: userMarkers.length > 5 ? userMarkers.length - 5 + "+" : ""
                    coloredBackground: highlighted
                    foreground: "grey"
                    font.pointSize: 8
                }
            
                Repeater {
                    model: userMarkers.length > 5 ? userMarkers.slice(0, 5) : userMarkers
            
                    ImageItem {
                        width: parent.height
                        height: parent.height
            
                        hint: modelData.displayName
                        image: modelData.avatar
            
                        MouseArea {
                            anchors.fill: parent
            
                            cursorShape: Qt.PointingHandCursor
            
                            onClicked: {
                                readMarkerDialog.listModel = userMarkers
                                readMarkerDialog.open()
                            }
                        }
                    }
                }
            
                TimelineLabel {
                    id: timeLabel
            
                    // NB: text must be empty when hidden - a hidden label that
                    // still holds a date keeps its implicitWidth, which widens
                    // the bubble for a timestamp nobody can see.
                    visible: messageRow.timeVisible
                    text: messageRow.timeVisible ? Qt.formatTime(time) : ""
                    coloredBackground: highlighted
                    foreground: "grey"
                    font.pointSize: 8
                }
            }
            
            ReactionDelegate {
                Layout.fillWidth: true
            }
            
            // FORK-ONLY: resend/discard ported from Aug 2019 (Controls 1
            // Label + MouseArea instead of Controls 2 hover links).
            Row {
                Layout.alignment: Qt.AlignRight

                spacing: 8
                visible: messageRow.failed

                TimelineLabel {
                    text: "Send failed:"
                    coloredBackground: highlighted
                    foreground: "grey"
                    font.pointSize: 8
                }

                TimelineLabel {
                    text: "Resend"
                    coloredBackground: highlighted
                    foreground: PPalette.accent
                    font.pointSize: 8
                    font.underline: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: currentRoom.retryMessage(eventId)
                    }
                }

                TimelineLabel {
                    text: "|"
                    coloredBackground: highlighted
                    foreground: "grey"
                    font.pointSize: 8
                }

                TimelineLabel {
                    text: "Discard"
                    coloredBackground: highlighted
                    foreground: PPalette.accent
                    font.pointSize: 8
                    font.underline: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: currentRoom.discardMessage(eventId)
                    }
                }
            }
        }

        Component {
            id: imageComponent

            DownloadableContent {
                width: messageImage.width
                height: messageImage.height

                id: downloadable

                TimelineImage {
                    z: -4

                    id: messageImage

                    sourceSize: 128
                    source: "image://mxc/" + (content.thumbnail_url ? content.thumbnail_url : content.url)

                    onClicked: downloadAndOpen()
                }

                Component.onCompleted: {
                    messageRow.saveFileAs.connect(saveFileAs)
                    messageRow.openExternally.connect(downloadAndOpen)
                }
            }
        }

        Component {
            id: fileComponent

            TimelineLabel {
                Layout.fillWidth: true

                id: downloadDelegate

                text: "<b>File: </b>" + content.body
                coloredBackground: highlighted

                background: DownloadableContent {
                    id: downloadable

                    Component.onCompleted: {
                        messageRow.saveFileAs.connect(saveFileAs)
                        messageRow.openExternally.connect(downloadAndOpen)
                    }
                }
            }
        }

        Component {
            id: audioComponent

            TimelineLabel {
                id: downloadDelegate

                text: content.info.duration / 1000 + '"'
                coloredBackground: highlighted

                MouseArea {
                    anchors.fill: parent

                    propagateComposedEvents: true

                    onClicked: {
                        if (downloadable.downloaded)
                            pcpController.playAudio(progressInfo.localPath)
                        else
                        {
                            playOnFinished = true
                            currentRoom.downloadFile(eventId, cacheLocation + "/" + eventId.replace(":", "_") + ".tmp")
                        }
                    }
                }

                background: DownloadableContent {
                    id: downloadable

                    onDownloadedChanged: downloaded && playOnFinished ? pcpController.playAudio(progressInfo.localPath) : {}

                    Component.onCompleted: {
                        messageRow.saveFileAs.connect(saveFileAs)
                        messageRow.openExternally.connect(downloadAndOpen)
                    }
                }
            }
        }
    }
}
