// SPDX-License-Identifier: GPL-3.0-only
// Public room directory browser, ported from Spectral (Dec 2019).
// Controls-1 adapted; upstream left click-to-join unwired, here a
// room click emits joinRequested(roomId).
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import PCP 0.1
import PCP.Component 2.0

ColumnLayout {
    property var connection

    signal joinRequested(string roomIdOrAlias)

    id: root

    spacing: 8

    // Manual alias/ID entry (kept from the old join dialog).
    AutoTextField {
        Layout.fillWidth: true

        id: aliasField
        placeholderText: "#matrix:matrix.org"

        Keys.onReturnPressed: {
            root.joinRequested(text)
        }
    }

    RowLayout {
        Layout.fillWidth: true

        spacing: 8

        AutoTextField {
            Layout.fillWidth: true

            id: keywordField
            placeholderText: "Search rooms"

            Keys.onReturnPressed: publicRoomListModel.keyword = text
        }

        AutoTextField {
            Layout.preferredWidth: 120

            id: serverField
            placeholderText: "Server"

            Keys.onReturnPressed: publicRoomListModel.server = text
        }
    }

    AutoListView {
        Layout.fillWidth: true
        Layout.preferredHeight: 320

        id: publicRoomsListView

        clip: true
        spacing: 4

        model: PublicRoomListModel {
            id: publicRoomListModel

            connection: root.connection
        }

        delegate: PItemDelegate {
            width: publicRoomsListView.width
            height: 48

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4

                spacing: 8

                // FORK-ONLY: the directory models hand out an mxc id
                // (server/mediaId), not a QImage like the room/user models
                // do, so resolve it through the mxc image provider instead
                // of ImageItem (whose image property is typed QImage).
                Image {
                    Layout.preferredWidth: height
                    Layout.fillHeight: true
                    sourceSize.height: height

                    source: avatar ? "image://mxc/" + avatar : ""
                    fillMode: Image.PreserveAspectCrop
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    spacing: 0

                    Label {
                        Layout.fillWidth: true

                        text: name
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Label {
                        Layout.fillWidth: true

                        visible: topic !== ""

                        text: topic
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }
            }

            onClicked: root.joinRequested(roomId)
        }

        onContentYChanged: {
            if (publicRoomListModel.hasMore
                    && contentHeight - contentY < publicRoomsListView.height + 200)
                publicRoomListModel.next()
        }
    }
}
