pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services" as Svc
import "../../Theme.qml" as Theme

RowLayout {
    Layout.alignment: Qt.AlignRight
    spacing: 6

    // Notifications with hover preview
    Item {
        implicitWidth: notifPill.width
        implicitHeight: Theme.pillHeight
        
        Rectangle {
            id: notifPill
            anchors.fill: parent
            implicitWidth: notifRow.implicitWidth + 20
            height: Theme.pillHeight
            radius: Theme.pillRadius
            color: notifMouseArea.containsPress ? Theme.surfaceHover : Theme.surface
            border.width: 1
            border.color: Svc.NotifStatus.hasNotifs ? Theme.yellow : Theme.border

            scale: notifMouseArea.containsMouse ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                id: notifRow
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: Svc.NotifStatus.icon
                    font.pixelSize: 12
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: Svc.NotifStatus.hasNotifs ? Theme.yellow : Theme.textMuted
                }
                Text {
                    visible: Svc.NotifStatus.hasNotifs
                    text: Math.min(Svc.NotifStatus.activeNotifications.length, 99).toString()
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: Theme.yellow
                }
            }

            MouseArea {
                id: notifMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        Svc.NotifStatus.toggleDnd()
                    } else {
                        shellRoot.togglePanel()
                    }
                }
                
                onEntered: notifPreviewTimer.start()
                onExited: {
                    notifPreviewTimer.stop()
                    notifPreview.visible = false
                }
            }
        }
        
        // Notification preview popup on hover
        Rectangle {
            id: notifPreview
            visible: false
            anchors.top: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.rightMargin: -8
            width: 300
            height: Math.min(Math.max(notifPreviewContent.implicitHeight + 20, 80), 250)
            radius: Theme.pillRadius
            color: Theme.surface
            border.width: 1
            border.color: Theme.yellow
            z: 1000
            
            ColumnLayout {
                id: notifPreviewContent
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                clip: true
                
                Text {
                    text: "Recent Notifications"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: Theme.yellow
                }
                
                ListView {
                    id: previewList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: Svc.NotifStatus.activeNotifications.slice(0, 3)
                    spacing: 4
                    clip: true
                    
                    delegate: Item {
                        required property var modelData
                        width: parent.width
                        height: previewText.implicitHeight + 4
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 2
                            
                            Text {
                                text: modelData.appName || "App"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.family: "JetBrainsMonoNL Nerd Font"
                                color: Theme.cyan
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                id: previewText
                                text: modelData.summary || ""
                                font.pixelSize: 9
                                font.family: "JetBrainsMonoNL Nerd Font"
                                color: Theme.textMuted
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
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

    // Network
    Rectangle {
        id: netPill
        implicitWidth: netRow.implicitWidth + 20
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: netMouseArea.containsPress ? Theme.surfaceHover : Theme.surface
        border.width: 1
        border.color: Svc.Network.connected ? Theme.blue : Theme.border

        scale: netMouseArea.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: netRow
            anchors.centerIn: parent
            spacing: 4
            Text {
                text: Svc.Network.connected ? "󰖩" : "󰖪"
                font.pixelSize: 12
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Network.connected ? Theme.blue : Theme.textMuted
            }
            Text {
                visible: Svc.Network.connected
                text: Svc.Network.label
                font.pixelSize: 11
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.blue
            }
        }

        MouseArea {
            id: netMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Svc.Network.openManager()
        }
    }

    // Bluetooth
    Rectangle {
        id: btPill
        implicitWidth: btRow.implicitWidth + 20
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: btMouseArea.containsPress ? Theme.surfaceHover : Theme.surface
        border.width: 1
        border.color: Svc.Bluetooth.enabled ? Theme.blue : Theme.border

        scale: btMouseArea.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: btRow
            anchors.centerIn: parent
            spacing: 4
            Text {
                text: Svc.Bluetooth.icon
                font.pixelSize: 12
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Bluetooth.enabled ? Theme.blue : Theme.textMuted
            }
            Text {
                visible: Svc.Bluetooth.enabled && Svc.Bluetooth.deviceCount > 0
                text: Svc.Bluetooth.deviceCount.toString()
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.blue
            }
        }

        MouseArea {
            id: btMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Svc.Bluetooth.openManager()
        }
    }

    // CPU
    Rectangle {
        id: cpuPill
        implicitWidth: cpuRow.implicitWidth + 20
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: cpuMouseArea.containsPress ? Theme.surfaceHover : Theme.surface
        border.width: 1
        border.color: Theme.purple

        scale: cpuMouseArea.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: cpuRow
            anchors.centerIn: parent
            spacing: 4
            Text {
                text: "󰻠"
                font.pixelSize: 12
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.purple
            }
            Text {
                text: Svc.CPU.text
                font.pixelSize: 11
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.purple
            }
        }

        MouseArea {
            id: cpuMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
        }
    }

    // RAM
    Rectangle {
        id: ramPill
        implicitWidth: ramRow.implicitWidth + 20
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: ramMouseArea.containsPress ? Theme.surfaceHover : Theme.surface
        border.width: 1
        border.color: Theme.pink

        scale: ramMouseArea.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: ramRow
            anchors.centerIn: parent
            spacing: 4
            Text {
                text: "󰍛"
                font.pixelSize: 12
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.pink
            }
            Text {
                text: Svc.Memory.text
                font.pixelSize: 11
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.pink
            }
        }

        MouseArea {
            id: ramMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
        }
    }

    // Power Profile (PROMINENT)
    Rectangle {
        id: pwrPill
        implicitWidth: pwrRow.implicitWidth + 20
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: pwrMouseArea.containsPress ? Theme.surfaceHover : Theme.surface
        border.width: 2
        border.color: {
            if (Svc.PowerProfile.full === "performance") return Theme.red
            if (Svc.PowerProfile.full === "power-saver") return Theme.green
            return Theme.cyan
        }

        scale: pwrMouseArea.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 300 } }

        RowLayout {
            id: pwrRow
            anchors.centerIn: parent
            spacing: 4
            Text {
                text: {
                    if (Svc.PowerProfile.full === "performance") return "󱐋"
                    if (Svc.PowerProfile.full === "power-saver") return "󰌪"
                    return "󰅐"
                }
                font.pixelSize: 12
                font.family: "JetBrainsMonoNL Nerd Font"
                color: {
                    if (Svc.PowerProfile.full === "performance") return Theme.red
                    if (Svc.PowerProfile.full === "power-saver") return Theme.green
                    return Theme.cyan
                }
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            Text {
                text: Svc.PowerProfile.text
                font.pixelSize: 11
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: {
                    if (Svc.PowerProfile.full === "performance") return Theme.red
                    if (Svc.PowerProfile.full === "power-saver") return Theme.green
                    return Theme.cyan
                }
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }

        MouseArea {
            id: pwrMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Svc.PowerProfile.cycle()
        }
    }

    // Battery
    Rectangle {
        id: batPill
        implicitWidth: batRow.implicitWidth + 20
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: batMouseArea.containsPress ? Theme.surfaceHover : Theme.surface
        border.width: 1
        border.color: Svc.Battery.status === "low" ? Theme.red : Theme.green

        scale: batMouseArea.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: batRow
            anchors.centerIn: parent
            spacing: 4
            Text {
                text: {
                    if (Svc.Battery.charging) return "󰂄"
                    if (Svc.Battery.status === "low") return "󰁚"
                    return "󰁹"
                }
                font.pixelSize: 12
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Battery.charging ? Theme.green : (Svc.Battery.status === "low" ? Theme.red : Theme.green)
            }
            Text {
                text: Svc.Battery.level + "%"
                font.pixelSize: 11
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Battery.charging ? Theme.green : (Svc.Battery.status === "low" ? Theme.red : Theme.green)
            }
        }

        MouseArea {
            id: batMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
        }
    }

    // Volume
    Rectangle {
        id: volPill
        implicitWidth: volRow.implicitWidth + 20
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: volMouseArea.containsPress ? Theme.surfaceHover : Theme.surface
        border.width: 1
        border.color: Svc.Audio.muted ? Theme.border : Theme.blue

        scale: volMouseArea.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: volRow
            anchors.centerIn: parent
            spacing: 4
            Text {
                text: Svc.Audio.muted ? "󰖁" : (Svc.Audio.percent > 66 ? "󰕾" : (Svc.Audio.percent > 33 ? "󰖀" : "󰖁"))
                font.pixelSize: 12
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Audio.muted ? Theme.textMuted : Theme.blue
            }
            Text {
                text: Svc.Audio.percent + "%"
                font.pixelSize: 11
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Audio.muted ? Theme.textMuted : Theme.blue
            }
        }

        MouseArea {
            id: volMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) Svc.Audio.openControl()
                else Svc.Audio.toggleMute()
            }
        }
    }

    // Panel access indicator (far right - only shows on hover)
    Item {
        width: 0
        height: Theme.pillHeight
        clip: true
        
        states: [
            State {
                name: "visible"
                when: statusRowMouseArea.containsMouse
                PropertyChanges { target: parent; width: 32 }
            }
        ]
        
        transitions: Transition {
            to: "visible"
            NumberAnimation { property: "width"; duration: 200; easing.type: Easing.InOutQuad }
        }

        Rectangle {
            id: panelPill
            width: 32
            height: parent.height
            radius: Theme.pillRadius
            color: shellRoot.panelOpen ? Theme.accentMedium : Theme.surface
            border.width: 1
            border.color: shellRoot.panelOpen ? Theme.cyan : Theme.border
            
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "⚙"
                font.pixelSize: 14
                font.family: "JetBrainsMonoNL Nerd Font"
                color: shellRoot.panelOpen ? Theme.cyan : Theme.textMuted
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: shellRoot.togglePanel()
            }
        }
    }
    
    MouseArea {
        id: statusRowMouseArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        
        onPositionChanged: mouse => mouse.accepted = false
    }
}
