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
    WlrLayershell.namespace: "quickshell-volume-osd"
    exclusiveZone: 0
    color: "transparent"
    
    implicitWidth: 200
    implicitHeight: 60

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
                text: Svc.Audio.muted ? "󰝟" : (Svc.Audio.percent > 66 ? "" : (Svc.Audio.percent > 33 ? "" : ""))
                color: Svc.Audio.muted ? Theme.textMuted : Theme.blue
                font.pixelSize: 20
                font.family: "JetBrainsMonoNL Nerd Font"
            }
            Text {
                text: Svc.Audio.percent + "%"
                color: Theme.text
                font.pixelSize: 16
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
            }
        }
    }

    function show() {
        visible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.visible = false
    }
}
