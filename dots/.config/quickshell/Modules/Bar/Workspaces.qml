pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services" as Svc
import "../../Theme.qml" as Theme

RowLayout {
    spacing: 6
    Layout.alignment: Qt.AlignLeft

    Repeater {
        model: 5

        Item {
            required property int index
            property int wsId: index + 1
            property bool active: Svc.Workspaces.active === wsId

            width: active ? 36 : 28
            height: Theme.wsHeight

            Rectangle {
                id: wsRect
                anchors.fill: parent
                radius: Theme.wsRadius
                color: parent.active ? Qt.rgba(0.31, 0.84, 1.0, 0.15) : Theme.surface
                border.width: 1
                border.color: parent.active ? Qt.rgba(0.31, 0.84, 1.0, 0.4) : Theme.border

                Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                // Active glow effect - more prominent
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.active ? 6 : 0
                    height: parent.active ? 6 : 0
                    radius: 3
                    color: Theme.cyan
                    opacity: parent.active ? 1.0 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on width { NumberAnimation { duration: 200 } }
                    Behavior on height { NumberAnimation { duration: 200 } }
                    
                    // Subtle pulsing animation for active workspace
                    SequentialAnimation on scale {
                        running: parent.visible && parent.parent.active
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 0.8
                            to: 1.2
                            duration: 1000
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            from: 1.2
                            to: 0.8
                            duration: 1000
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: wsId.toString()
                font.pixelSize: 11
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: parent.active ? Theme.cyan : Theme.textDim
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: Svc.Workspaces.switchTo(wsId)
                
                onEntered: {
                    if (!parent.active) parent.scale = 1.08
                }
                onExited: {
                    if (!parent.active) parent.scale = 1.0
                }
            }
            
            scale: 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        }
    }
}
