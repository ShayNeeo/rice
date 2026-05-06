pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services" as Svc
import "../../Theme.qml" as Theme
import "."

PanelWindow {
    id: barWindow
    
    property var screen
    visible: true

    anchors {

        top: true
        left: true
        right: true
    }

    exclusiveZone: Theme.barHeight
    WlrLayershell.namespace: "quickshell-bar"
    aboveWindows: true
    focusable: false
    implicitHeight: Theme.barHeight

    color: Theme.bg

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 4

        Workspaces {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
        }
        Clock {
            Layout.alignment: Qt.AlignHCenter
        }
        StatusPills {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
        }
    }

    Rectangle {
        id: notifPopup
        visible: false
        anchors.right: parent.right
        anchors.top: parent.bottom
        anchors.rightMargin: 10
        anchors.topMargin: 6
        width: 350
        height: notifContent.implicitHeight + 24
        radius: 12
        color: Theme.surface
        border.width: 1
        border.color: Theme.borderAccent
        z: 100

        property string summary: ""
        property string body: ""
        property string appName: ""

        Connections {
            target: Svc.NotifStatus
            function onNotifVersionChanged() {
                notifPopup.summary = Svc.NotifStatus.lastSummary
                notifPopup.body = Svc.NotifStatus.lastBody
                notifPopup.appName = Svc.NotifStatus.lastAppName
                notifPopup.visible = true
                notifHideTimer.restart()
            }
        }

        Timer {
            id: notifHideTimer
            interval: 8000
            onTriggered: notifPopup.visible = false
        }

        ColumnLayout {
            id: notifContent
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "󰎟"
                    font.pixelSize: 14
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: Theme.cyan
                }
                Text {
                    Layout.fillWidth: true
                    text: notifPopup.appName || "Notification"
                    font.pixelSize: 10
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: Theme.textMuted
                    elide: Text.ElideRight
                }
                Text {
                    text: "✕"
                    font.pixelSize: 10
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: Theme.textDim
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notifPopup.visible = false
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                text: notifPopup.summary
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.text
                wrapMode: Text.WordWrap
            }
            Text {
                Layout.fillWidth: true
                visible: notifPopup.body !== ""
                text: notifPopup.body
                font.pixelSize: 11
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.textDim
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: notifPopup.visible = false
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: shellRoot.panelOpen || shellRoot.dropdownOpen
        onClicked: {
            shellRoot.closePanel()
            shellRoot.closeDropdown()
        }
    }
}
