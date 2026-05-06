pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Svc
import "Modules/Bar"

PanelWindow {
    id: barWindow
    
    property var screen

    anchors {
        top: true
        left: true
        right: true;
    }

    exclusiveZone: 28
    WlrLayershell.namespace: "quickshell-bar"
    aboveWindows: true
    focusable: false
    implicitHeight: 28
    
    color: "#0a0b13"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 3

        Repeater {
            model: 5
            Item {
                required property int index
                property int wsId: index + 1
                property bool active: Svc.Workspaces.active === wsId
                width: active ? 20 : 16
                height: 20
                
                Text {
                    anchors.centerIn: parent
                    text: wsId.toString()
                    font.pixelSize: 8
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: parent.active ? "#4fd6ff" : "#5a5e7a"
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Svc.Workspaces.switchTo(wsId)
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            height: 20
            
            Text {
                anchors.centerIn: parent
                text: Svc.Clock.time
                font.pixelSize: 10
                font.family: "JetBrainsMonoNL Nerd Font"
                color: "#4fd6ff"
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        shellRoot.togglePanel()
                    }
                }
            }
        }

        RowLayout {
            spacing: 3
            height: 20
            Layout.alignment: Qt.AlignRight
            
            Text {
                visible: Svc.Battery.present
                text: {
                    if (Svc.Battery.charging) return "󰂄 " + Svc.Battery.level + "%"
                    if (Svc.Battery.critical) return "󰁚 " + Svc.Battery.level + "%"
                    return "󰁹 " + Svc.Battery.level + "%"
                }
                font.pixelSize: 8
                font.family: "JetBrainsMonoNL Nerd Font"
                color: {
                    if (Svc.Battery.critical) return "#ff6b6b"
                    if (Svc.Battery.warning) return "#ffcc66"
                    return "#9ee8b8"
                }
            }
            
            Text {
                text: {
                    if (Svc.PowerProfile.full === "performance") return "P"
                    if (Svc.PowerProfile.full === "power-saver") return "S"
                    return "B"
                }
                font.pixelSize: 8
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: {
                    if (Svc.PowerProfile.full === "performance") return "#ff6b6b"
                    if (Svc.PowerProfile.full === "power-saver") return "#9ee8b8"
                    return "#4fd6ff"
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Svc.PowerProfile.cycle()
                }
            }
        }
    }
}
