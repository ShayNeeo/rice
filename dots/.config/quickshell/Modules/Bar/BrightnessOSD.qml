pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services" as Svc

PanelWindow {
    id: root
    visible: false
    WlrLayershell.namespace: "quickshell-brightness-osd"
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 200
    implicitHeight: 60

    Rectangle {
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        width: 180
        height: 48
        radius: 24
        color: "#1c1e30"
        border.color: "#2e3048"
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 12
            Text {
                text: "\uDB80\uCC22"
                color: "#ffcc66"
                font.pixelSize: 20
                font.family: "JetBrainsMonoNL Nerd Font"
            }
            Text {
                text: Math.round(Svc.Brightness.brightness * 100) + "%"
                color: "#dde0f0"
                font.pixelSize: 16
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
            }
        }
    }

    function show() { visible = true; hideTimer.restart() }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.visible = false
    }
}
