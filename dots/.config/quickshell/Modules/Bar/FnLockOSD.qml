pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: false
    WlrLayershell.namespace: "quickshell-fnlock-osd"
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 200
    implicitHeight: 60

    property bool fnlockActive: false

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
                text: root.fnlockActive ? "\uDB80\uF632" : "\uDB80\uF633"
                color: root.fnlockActive ? "#4fd6ff" : "#6a6e8a"
                font.pixelSize: 20
                font.family: "JetBrainsMonoNL Nerd Font"
            }
            Text {
                text: root.fnlockActive ? "Fn Lock ON" : "Fn Lock OFF"
                color: "#dde0f0"
                font.pixelSize: 16
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
            }
        }
    }

    function show(active: bool) { fnlockActive = active; visible = true; hideTimer.restart() }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.visible = false
    }
}
