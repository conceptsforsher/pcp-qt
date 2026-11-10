import QtQuick 2.6

RoomPanelForm {
    roomHeader.onClicked: roomDrawer.open()
    roomHeader.image: pcpController.safeImage(currentRoom ? currentRoom.avatar : null)
    roomHeader.topic: currentRoom ? (currentRoom.topic).replace(/(\r\n\t|\n|\r\t)/gm,"") : ""

    sortedMessageEventModel.onModelReset: {
        if (currentRoom)
        {
            var lastScrollPosition = sortedMessageEventModel.mapFromSource(currentRoom.savedTopVisibleIndex())
            console.log("Scrolling to position", lastScrollPosition)
            // FORK-ONLY: this used to be `currentIndex = lastScrollPosition`.
            // Setting currentIndex marks the current item and scrolls nothing,
            // so the view kept whatever contentY it had - and since the
            // timeline is BottomToTop, a stale contentY leaves the NEWEST
            // message below the visible area, under the input bar, while the
            // room list (Room::lastEvent()) happily shows it. Say what the
            // view is actually showing, so that is checkable.
            console.log("Timeline: rows=" + sortedMessageEventModel.count
                        + " contentHeight=" + messageListView.contentHeight
                        + " contentY=" + messageListView.contentY
                        + " originY=" + messageListView.originY
                        + " height=" + messageListView.height
                        + " rowAtBottom="
                        + messageListView.indexAt(messageListView.contentX,
                                                  messageListView.contentY
                                                  + messageListView.height - 1)
                        + " lastEvent=[" + currentRoom.lastEvent() + "]"
                        + " row0=[" + (sortedMessageEventModel.count > 0
                                        ? sortedMessageEventModel.get(0).display
                                        : "") + "]")
            if (lastScrollPosition > 0)
                messageListView.positionViewAtIndex(lastScrollPosition, ListView.Center)
            else
                // 0 means "at the newest end" (savedTopVisibleIndex returns 0
                // for that), -1 means the proxy could not map it: either way
                // the newest message is what should be on screen.
                messageListView.positionViewAtEnd()
            if (messageListView.contentY < messageListView.originY + 10 || currentRoom.timelineSize === 0)
                currentRoom.getPreviousContent(100)
        }
        console.log("Model timeline reset")
    }

    messageListView {
        property int largestVisibleIndex: messageListView.count > 0 ? messageListView.indexAt(messageListView.contentX, messageListView.contentY + messageListView.height - 1) : -1

        onContentYChanged: {
            if(currentRoom && messageListView.contentY  - 5000 < messageListView.originY)
                currentRoom.getPreviousContent(50);
        }

        onMovementEnded: {
            currentRoom.saveViewport(sortedMessageEventModel.mapToSource(messageListView.indexAt(messageListView.contentX, messageListView.contentY)), sortedMessageEventModel.mapToSource(largestVisibleIndex))
            var newReadMarker = sortedMessageEventModel.get(largestVisibleIndex).eventId
            if (newReadMarker) currentRoom.readMarkerEventId = newReadMarker
        }

        displaced: Transition {
            NumberAnimation {
                property: "y"; duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }

    goBottomFab.onClicked: goToEvent(currentRoom.readMarkerEventId)
    goTopFab.onClicked: messageListView.positionViewAtBeginning()

    function goToEvent(eventID) {
        var index = messageEventModel.eventIDToIndex(eventID)
        if (index === -1) return
        messageListView.currentIndex = sortedMessageEventModel.mapFromSource(index)
    }
}
