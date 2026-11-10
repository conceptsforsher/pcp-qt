import QtQuick 2.6

import PCP.Setting 0.1

MouseArea {
    signal primaryClicked()
    signal secondaryClicked()

    acceptedButtons: PSettings.pressAndHold ? Qt.LeftButton : (Qt.LeftButton | Qt.RightButton)

    onClicked: mouse.button == Qt.RightButton ? secondaryClicked() : primaryClicked()
    onPressAndHold: PSettings.pressAndHold ? secondaryClicked() : {}
}
