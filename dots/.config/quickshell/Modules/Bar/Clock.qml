pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services" as Svc
import "../../Theme.qml" as Theme

Item {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

    property bool showDate: false

    Text {
        anchors.centerIn: parent
        text: showDate ? Svc.Clock.date : Svc.Clock.time
        font.pixelSize: 13
        font.weight: Font.Bold
        font.family: "JetBrainsMonoNL Nerd Font"
        color: Theme.cyan
        
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
        opacity: 1.0
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                showDate = !showDate
                if (showDate) {
                    dateTimer.restart()
                }
            } else {
                shellRoot.togglePanel()
            }
        }
        
        onEntered: parent.scale = 1.05
        onExited: parent.scale = 1.0
    }
    
    scale: 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }

    Timer {
        id: dateTimer
        interval: 3000
        onTriggered: showDate = false
    }
}
