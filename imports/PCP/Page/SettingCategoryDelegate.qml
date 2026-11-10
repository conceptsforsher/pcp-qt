import QtQuick 2.6
import QtQuick.Controls 1.4

import PCP.Component 2.0

PItemDelegate {
    text: category

    onClicked: {
        settingStackView.clear()
        settingStackView.push([accountForm, generalForm, appearanceForm, aboutForm][form])
    }
}
