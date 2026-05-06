pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import "../../services" as Svc

RowLayout {
    id: root
    spacing: 8

    signal openPanel()

    // Helper for indicator style
    component Indicator : Rectangle {
        width: 32
        height: Theme.pillHeight || 28
        color: Theme.surface
        radius: Theme.pillRadius || 10
        border.color: Theme.border
        border.width: 1

        Text {
            id: iconText
            anchors.centerIn: parent
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"
        }
    }

    // Notifications
    Indicator {
        Text {
            anchors.centerIn: parent
            text: Svc.NotifStatus.icon
            color: Theme.yellow
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"
        }
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            text: Svc.NotifStatus.count > 0 ? Svc.NotifStatus.count.toString() : ""
            color: Theme.red
            font.pixelSize: 9
            font.family: "JetBrainsMonoNL Nerd Font"
            font.bold: true
            visible: Svc.NotifStatus.count > 0
        }
    }

    // Wifi
    Indicator {
        Text {
            anchors.centerIn: parent
            text: Svc.Network.connected ? "󰖩" : "󰖪"
            color: Svc.Network.connected ? Theme.cyan : Theme.textMuted
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"
        }
        ToolTip {
            visible: parent.hovered
            text: Svc.Network.label || "Disconnected"
        }
    }

    // Bluetooth
    Indicator {
        Text {
            anchors.centerIn: parent
            text: Svc.Bluetooth.icon
            color: Svc.Bluetooth.enabled ? Theme.blue : Theme.textMuted
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"
        }
        ToolTip {
            visible: parent.hovered
            text: "Devices: " + Svc.Bluetooth.deviceCount
        }
    }

    // CPU
    Indicator {
        Text {
            anchors.centerIn: parent
            text: "󰻠"
            color: Theme.purple
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"
        }
        ToolTip {
            visible: parent.hovered
            text: "CPU: " + Svc.CPU.text
        }
    }

    // RAM
    Indicator {
        Text {
            anchors.centerIn: parent
            text: "󰍛"
            color: Theme.pink
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"
        }
        ToolTip {
            visible: parent.hovered
            text: "RAM: " + Svc.Memory.text
        }
    }

    // Power Profile
    Indicator {
        Text {
            anchors.centerIn: parent
            text: {
                if (Svc.PowerProfile.full === "performance") return "󱐋"
                if (Svc.PowerProfile.full === "power-saver") return "󰌪"
                return "󰅐"
            }
            color: {
                if (Svc.PowerProfile.full === "performance") return Theme.red
                if (Svc.PowerProfile.full === "power-saver") return Theme.green
                return Theme.cyan
            }
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"
        }
        ToolTip {
            visible: parent.hovered
            text: "Power Profile: " + Svc.PowerProfile.full
        }
    }

    // Battery
    Indicator {
        visible: Svc.Battery.present
        Text {
            anchors.centerIn: parent
            text: Svc.Battery.charging ? "󰂄" : " torch" // simplified for now
            // Note: Battery icon depends on state
            text: {
                if (Svc.Battery.charging) return "󰂄"
                if (Svc.Battery.status === "low") return "󰁚"
                return "󰁹"
            }
            color: Svc.Battery.charging ? Theme.green : (Svc.Battery.status === "low" ? Theme.red : Theme.green)
            font.pixelSize: 14
            font.family: "JetBrainsMonoNL Nerd Font"
        }
        ToolTip {
            visible: parent.hovered
            text: Svc.Battery.level + "% (" + Svc.Battery.status + ")"
        }
    }

    // Tray
    RowLayout {
        spacing: 4
        Repeater {
            model: Svc.Tray.apps
            Rectangle {
                width: 24; height: 24; color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰑇" // Generic tray icon
                    color: Theme.text
                    font.pixelSize: 12
                    font.family: "JetBrainsMonoNL Nerd Font"
                }
            }
        }
    }

    // Hidden "A" icon
    Rectangle {
        id: aIcon
        width: 30; height: Theme.pillHeight || 28
        color: "transparent"
        opacity: hoverArea.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            anchors.centerIn: parent
            text: "A"
            color: Theme.cyan
            font.pixelSize: 14
            font.weight: Font.Bold
            font.family: "JetBrainsMonoNL Nerd Font"
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.openPanel()
        }
    }
}
