pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Theme.qml" as Theme
import "../../services" as Svc

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
        id: pill
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        width: 180
        height: 48
        radius: 24
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 12
            Text {
                text: root.fnlockActive ? "󰘲" : "󰘳"
                color: root.fnlockActive ? Theme.cyan : Theme.textMuted
                font.pixelSize: 20
                font.family: "JetBrainsMonoNL Nerd Font"
            }
            Text {
                text: root.fnlockActive ? "Fn Lock ON" : "Fn Lock OFF"
                color: Theme.text
                font.pixelSize: 16
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
            }
        }
    }

    function show(active: bool) {
        fnlockActive = active
        visible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.visible = false
    }
}
