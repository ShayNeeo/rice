pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services" as Svc

RowLayout {
    spacing: 8

    Repeater {
        model: 5

        Item {
            required property int index
            property int wsId: index + 1
            property bool active: Svc.Workspaces.active === wsId

            implicitWidth: active ? 40 : 28
            implicitHeight: 26

            Rectangle {
                id: wsRect
                anchors.fill: parent
                radius: 8
                color: parent.active ? "#4fd6ff26" : "#1c1e30"
                border.width: 1
                border.color: parent.active ? "#4fd6ff" : "#2e3048"

                Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 4
                    width: parent.active ? 4 : 0
                    height: 4
                    radius: 2
                    color: "#4fd6ff"
                    opacity: parent.active ? 1.0 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on width { NumberAnimation { duration: 200 } }
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: parent.active ? -2 : 0
                text: {
                    switch(wsId) {
                        case 1: return "\uDB80\uDCA0"
                        case 2: return "\uDB80\uDCA2"
                        case 3: return "\uDB80\uDCA4"
                        case 4: return "\uDB80\uDCA6"
                        case 5: return "\uDB80\uDCA8"
                        default: return wsId.toString()
                    }
                }
                font.pixelSize: parent.active ? 14 : 12
                font.family: "JetBrainsMonoNL Nerd Font"
                color: parent.active ? "#4fd6ff" : "#7a7e9a"
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on font.pixelSize { NumberAnimation { duration: 200 } }
                Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 200 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: Svc.Workspaces.switchTo(wsId)

                onEntered: { if (!parent.active) parent.scale = 1.1 }
                onExited: { if (!parent.active) parent.scale = 1.0 }
            }

            scale: 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        }
    }
}
