pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../"
import "../../services" as Svc

PanelWindow {
    id: root

    color: "#000000"

    anchors {
        top: true
        left: true
        right: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 0

        // Left Section: Simplified Workspaces
        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 0

            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: 5
                    Rectangle {
                        width: 6; height: 6
                        radius: 3
                        color: Svc.Workspaces.active === index + 1 ? "#FFFFFF" : "#444444"
                    }
                }
            }
        }

        // Middle Section: Clock (Time only, no interaction)
        Item {
            Layout.fillWidth: true

            Text {
                anchors.centerIn: parent
                text: Svc.Clock.time
                color: "#FFFFFF"
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
            }
        }

        // Right Section: Battery and Low Power Icon
        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 0

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: Svc.Battery.level + "%"
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    font.family: "JetBrainsMonoNL Nerd Font"
                }

                Text {
                    text: "󰂂" // Low power icon
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    font.family: "JetBrainsMonoNL Nerd Font"
                }
            }
        }
    }
}
