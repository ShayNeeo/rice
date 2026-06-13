pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Svc

PanelWindow {
    id: barWindow

    readonly property string bg_: "#0e0f18"
    readonly property string surface: "#161824"
    readonly property string border: "#222430"
    readonly property string cyan: "#4fd6ff"
    readonly property string green: "#7ec8a0"
    readonly property string red: "#d06060"
    readonly property string textColor: "#c0c4d8"
    readonly property string textMuted: "#6a6e88"

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: 24
    WlrLayershell.namespace: "quickshell-bar"
    aboveWindows: true
    focusable: false
    implicitHeight: 24
    color: bg_

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter
            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    width: 16
                    height: 16
                    radius: 0
                    color: Svc.Workspaces.active === (index + 1) ? cyan : surface
                    Text {
                        anchors.centerIn: parent
                        text: (index + 1).toString()
                        font.pixelSize: 8
                        font.family: "JetBrainsMonoNL Nerd Font"
                        color: Svc.Workspaces.active === (index + 1) ? bg_ : textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Svc.Workspaces.switchTo(index + 1)
                    }
                }
            }
        }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Svc.Clock.time
            font.pixelSize: 10
            font.weight: Font.Bold
            font.family: "JetBrainsMonoNL Nerd Font"
            color: cyan
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: shellRoot.togglePanel()
            }
        }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            Text {
                visible: Svc.Battery.present
                text: (Svc.Battery.charging ? "+" : "B") + " " + Svc.Battery.level + "%"
                font.pixelSize: 9
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Battery.charging ? green : (Svc.Battery.level <= 15 ? red : green)
            }

            Text {
                text: Svc.PowerProfile.text
                font.pixelSize: 9
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: green
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Svc.PowerProfile.cycle()
                }
            }
        }
    }
}
