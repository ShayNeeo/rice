pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services" as Svc

RowLayout {
    Layout.alignment: Qt.AlignRight
    spacing: 6

    property string surface: "#1c1e30"
    property string surfaceHover: "#26283a"
    property string border: "#2e3048"
    property string cyan: "#4fd6ff"
    property string yellow: "#ffcc66"
    property string green: "#9ee8b8"
    property string red: "#ff6b6b"
    property string purple: "#cdb7ff"
    property string blue: "#7ec8ff"
    property string pink: "#a0b8ff"
    property string textMuted: "#6a6e8a"
    property string textDim: "#7a7e9a"
    property string textColor: "#dde0f0"
    property int pillH: 28
    property int pillR: 10

    // ---- Notifications ----
    Rectangle {
        id: notifPill
        implicitWidth: notifRow.implicitWidth + 14
        height: pillH
        radius: pillR
        color: notifMA.containsPress ? surfaceHover : surface
        border.width: 1
        border.color: Svc.NotifStatus.hasNotifs ? yellow : border
        scale: notifMA.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: notifRow
            anchors.centerIn: parent
            spacing: 3
            Text {
                text: Svc.NotifStatus.hasNotifs ? "!" : "N"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.NotifStatus.hasNotifs ? yellow : textMuted
            }
            Text {
                visible: Svc.NotifStatus.hasNotifs
                text: Math.min(Svc.NotifStatus.count, 99).toString()
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: yellow
            }
        }

        MouseArea {
            id: notifMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: shellRoot.togglePanel()
            onEntered: notifPreviewTimer.start()
            onExited: { notifPreviewTimer.stop(); notifPreview.visible = false }
        }

        Rectangle {
            id: notifPreview
            visible: false
            anchors.top: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: 6
            width: 280
            height: Math.min(Math.max(notifPrevContent.implicitHeight + 16, 60), 200)
            radius: pillR
            color: surface
            border.width: 1
            border.color: yellow
            z: 1000
            ColumnLayout {
                id: notifPrevContent
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                clip: true
                Text {
                    text: "Notifications"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: yellow
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: Svc.NotifStatus.activeNotifications.slice(0, 3)
                    spacing: 3
                    clip: true
                    delegate: Item {
                        required property var modelData
                        width: parent.width
                        height: 20
                        Text {
                            anchors.fill: parent
                            text: (modelData.appName || "App") + ": " + (modelData.summary || "")
                            font.pixelSize: 9
                            font.family: "JetBrainsMonoNL Nerd Font"
                            color: textDim
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
        Timer {
            id: notifPreviewTimer
            interval: 1500
            onTriggered: notifPreview.visible = true
        }
    }

    // ---- WiFi ----
    Rectangle {
        id: netPill
        implicitWidth: netRow.implicitWidth + 14
        height: pillH
        radius: pillR
        color: netMA.containsPress ? surfaceHover : surface
        border.width: 1
        border.color: Svc.Network.connected ? blue : border
        scale: netMA.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: netRow
            anchors.centerIn: parent
            spacing: 4
            Text {
                text: {
                    if (!Svc.Network.connected) return "x"
                    if (Svc.Network.signal > 75) return "4"
                    if (Svc.Network.signal > 50) return "3"
                    if (Svc.Network.signal > 25) return "2"
                    return "1"
                }
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Network.connected ? blue : textMuted
            }
            Text {
                visible: Svc.Network.connected
                text: Svc.Network.label
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: blue
            }
        }

        MouseArea {
            id: netMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Svc.Network.openManager()
        }
    }

    // ---- Bluetooth ----
    Rectangle {
        id: btPill
        implicitWidth: btRow.implicitWidth + 14
        height: pillH
        radius: pillR
        color: btMA.containsPress ? surfaceHover : surface
        border.width: 1
        border.color: Svc.Bluetooth.enabled ? blue : border
        scale: btMA.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: btRow
            anchors.centerIn: parent
            spacing: 3
            Text {
                text: Svc.Bluetooth.enabled ? "BT" : "--"
                font.pixelSize: 9
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Bluetooth.enabled ? blue : textMuted
            }
            Text {
                visible: Svc.Bluetooth.enabled && Svc.Bluetooth.deviceCount > 0
                text: Svc.Bluetooth.deviceCount.toString()
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: blue
            }
        }

        MouseArea {
            id: btMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Svc.Bluetooth.openManager()
        }
    }

    // ---- Volume ----
    Rectangle {
        id: volPill
        implicitWidth: volRow.implicitWidth + 14
        height: pillH
        radius: pillR
        color: volMA.containsPress ? surfaceHover : surface
        border.width: 1
        border.color: blue
        scale: volMA.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: volRow
            anchors.centerIn: parent
            spacing: 3
            Text {
                text: Svc.Audio.muted ? "M" : "V"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Audio.muted ? textMuted : blue
            }
            Text {
                text: Svc.Audio.percent + "%"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Audio.muted ? textMuted : blue
            }
        }

        MouseArea {
            id: volMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Svc.Audio.toggleMute()
            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) Svc.Audio.setVolume(Svc.Audio.percent + 5)
                else Svc.Audio.setVolume(Svc.Audio.percent - 5)
            }
        }
    }

    // ---- CPU ----
    Rectangle {
        id: cpuPill
        implicitWidth: cpuRow.implicitWidth + 14
        height: pillH
        radius: pillR
        color: cpuMA.containsPress ? surfaceHover : surface
        border.width: 1
        border.color: purple
        scale: cpuMA.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: cpuRow
            anchors.centerIn: parent
            spacing: 3
            Text {
                text: "C"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: purple
            }
            Text {
                text: Svc.CPU.text
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: purple
            }
        }

        MouseArea {
            id: cpuMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
        }
    }

    // ---- RAM ----
    Rectangle {
        id: ramPill
        implicitWidth: ramRow.implicitWidth + 14
        height: pillH
        radius: pillR
        color: ramMA.containsPress ? surfaceHover : surface
        border.width: 1
        border.color: pink
        scale: ramMA.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: ramRow
            anchors.centerIn: parent
            spacing: 3
            Text {
                text: "R"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: pink
            }
            Text {
                text: Svc.Memory.text
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: pink
            }
        }

        MouseArea {
            id: ramMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
        }
    }

    // ---- Battery ----
    Rectangle {
        id: batPill
        implicitWidth: batRow.implicitWidth + 14
        height: pillH
        radius: pillR
        color: batMA.containsPress ? surfaceHover : surface
        border.width: 1
        border.color: Svc.Battery.charging ? green : (Svc.Battery.level <= 15 ? red : green)
        scale: batMA.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: batRow
            anchors.centerIn: parent
            spacing: 3
            Text {
                text: Svc.Battery.charging ? "+" : "B"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Battery.charging ? green : (Svc.Battery.level <= 15 ? red : green)
            }
            Text {
                text: Svc.Battery.level + "%"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Battery.charging ? green : (Svc.Battery.level <= 15 ? red : green)
            }
        }

        MouseArea {
            id: batMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
        }
    }

    // ---- Power Profile ----
    Rectangle {
        id: profilePill
        implicitWidth: profileRow.implicitWidth + 14
        height: pillH
        radius: pillR
        color: profileMA.containsPress ? surfaceHover : surface
        border.width: 1
        border.color: border
        scale: profileMA.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: profileRow
            anchors.centerIn: parent
            spacing: 3
            Text {
                text: Svc.PowerProfile.text
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.PowerProfile.full === "performance" ? red : (Svc.PowerProfile.full === "power-saver" ? green : cyan)
            }
        }

        MouseArea {
            id: profileMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Svc.PowerProfile.cycle()
        }
    }

    // ---- Tray ----
    RowLayout {
        id: trayLayout
        spacing: 2
        Repeater {
            model: Svc.Tray.apps
            Rectangle {
                required property string modelData
                width: 20
                height: 20
                color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: {
                        switch (modelData) {
                            case "discord": return "D"
                            case "telegram-desktop": return "T"
                            case "slack": return "S"
                            case "steam": return "St"
                            case "spotify": return "Sp"
                            case "obs": return "O"
                            case "nm-applet": return "N"
                            case "blueman-applet": return "B"
                            default: return "*"
                        }
                    }
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: textDim
                }
            }
        }
    }

    // ---- Panel access (far right, hover to reveal) ----
    Item {
        width: statusRowMA.containsMouse ? 28 : 0
        height: pillH
        clip: true
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        Rectangle {
            width: 28
            height: parent.height
            radius: pillR
            color: shellRoot.panelOpen ? "#4fd6ff66" : surface
            border.width: 1
            border.color: shellRoot.panelOpen ? cyan : border
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: ">"
                font.pixelSize: 14
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: shellRoot.panelOpen ? cyan : textMuted
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: shellRoot.togglePanel()
            }
        }
    }

    // Background hover zone - now just a small area for the panel trigger
    Rectangle {
        width: 12
        height: pillH
        color: "transparent"
        
        MouseArea {
            id: statusRowMA
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
        }
    }
}
