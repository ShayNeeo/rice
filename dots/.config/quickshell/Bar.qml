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

    readonly property string bg: "#0f101b"
    readonly property string surface: "#1c1e30"
    readonly property string surfaceHover: "#26283a"
    readonly property string border: "#2e3048"
    readonly property string borderAccent: "#4fd6ff4d"
    readonly property string accentFaint: "#4fd6ff26"
    readonly property string cyan: "#4fd6ff"
    readonly property string yellow: "#ffcc66"
    readonly property string green: "#9ee8b8"
    readonly property string red: "#ff6b6b"
    readonly property string purple: "#cdb7ff"
    readonly property string blue: "#7ec8ff"
    readonly property string pink: "#a0b8ff"
    readonly property string textColor: "#dde0f0"
    readonly property string textMuted: "#6a6e8a"
    readonly property string textDim: "#7a7e9a"
    readonly property int barH: 38
    readonly property int pillH: 28
    readonly property int pillR: 10
    readonly property int wsH: 26
    readonly property int wsR: 8

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: barH
    WlrLayershell.namespace: "quickshell-bar"
    aboveWindows: true
    focusable: false
    implicitHeight: barH
    color: "#00000000"

    Workspaces {
        id: leftWidgets
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    Clock {
        id: centerWidgets
        anchors.centerIn: parent
    }

    StatusPills {
        id: rightWidgets
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
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
        color: surface
        border.width: 1
        border.color: borderAccent
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
                    text: "\uDB80\uDE9F"
                    font.pixelSize: 14
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: cyan
                }
                Text {
                    Layout.fillWidth: true
                    text: notifPopup.appName || "Notification"
                    font.pixelSize: 10
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: textMuted
                    elide: Text.ElideRight
                }
                Text {
                    text: "\u2715"
                    font.pixelSize: 10
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: textDim
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
                color: textColor
                wrapMode: Text.WordWrap
            }
            Text {
                Layout.fillWidth: true
                visible: notifPopup.body !== ""
                text: notifPopup.body
                font.pixelSize: 11
                font.family: "JetBrainsMonoNL Nerd Font"
                color: textDim
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
