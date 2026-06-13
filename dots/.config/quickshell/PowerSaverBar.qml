pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Svc
import "Modules/Bar"

PanelWindow {
    id: barWindow

    readonly property string bg_: "#0f101b"
    readonly property string surface: "#1c1e30"
    readonly property string border: "#2e3048"
    readonly property string cyan: "#4fd6ff"
    readonly property string green: "#9ee8b8"
    readonly property string red: "#ff6b6b"
    readonly property string textColor: "#dde0f0"
    readonly property string textMuted: "#6a6e8a"

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: 28
    WlrLayershell.namespace: "quickshell-bar"
    aboveWindows: true
    focusable: false
    implicitHeight: 28
    color: bg_

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        Workspaces { Layout.alignment: Qt.AlignVCenter }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }

        Clock { Layout.alignment: Qt.AlignVCenter }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Text {
                visible: Svc.Battery.present
                text: (Svc.Battery.charging ? "+" : "B") + " " + Svc.Battery.level + "%"
                font.pixelSize: 9
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Svc.Battery.charging ? green : (Svc.Battery.level <= 15 ? red : green)
            }

            Rectangle {
                implicitWidth: profileText.implicitWidth + 14
                height: 24
                radius: 8
                color: surface
                border.width: 1
                border.color: border

                Text {
                    id: profileText
                    anchors.centerIn: parent
                    text: Svc.PowerProfile.text
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: Svc.PowerProfile.full === "power-saver" ? green : (Svc.PowerProfile.full === "performance" ? red : cyan)
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
