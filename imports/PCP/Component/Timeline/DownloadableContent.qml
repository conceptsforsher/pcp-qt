import QtQuick 2.6

import PCP.Style 0.1
// NOTE (Qt 5.6 port): Qt.labs.platform (StandardPaths) does not exist on
// Qt 5.6. The cache dir comes from the `cacheLocation` context property
// set in src/main.cpp from QStandardPaths::CacheLocation.

Item {
    property bool openOnFinished: false
    readonly property bool downloaded: progressInfo && progressInfo.completed

    Rectangle {
        z: -2
        height: parent.height
        width: progressInfo.active && !progressInfo.completed ? progressInfo.progress / progressInfo.total * parent.width : 0

        color: PPalette.accent
        opacity: 0.4
    }

    onDownloadedChanged: if (downloaded && openOnFinished) openSavedFile()

    function saveFileAs() { currentRoom.saveFileAs(eventId) }

    function downloadAndOpen()
    {
        if (downloaded) openSavedFile()
        else
        {
            openOnFinished = true
            var base = (typeof cacheLocation !== "undefined" && cacheLocation !== "") ? cacheLocation : "."
            currentRoom.downloadFile(eventId, base + "/" + eventId.replace(":", "_") + ".tmp")
        }
    }

    function openSavedFile()
    {
        if (Qt.openUrlExternally(progressInfo.localPath)) return;
        if (Qt.openUrlExternally(progressInfo.localDir)) return;
    }
}
