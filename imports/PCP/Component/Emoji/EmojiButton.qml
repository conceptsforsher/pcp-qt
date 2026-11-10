import QtQuick 2.6

Text {
    property string category

    width: 36
    height: 36

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    font.pointSize: 20
    font.family: "Emoji"

    MouseArea {
        anchors.fill: parent
        onClicked: emojiCategory = category
    }
}
