import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 38
    color: "#1c1e30"

    Text {
        anchors.centerIn: parent
        text: "TEST BAR - If you see this, quickshell works!"
        color: "#4fd6ff"
        font.pixelSize: 14
        font.family: "JetBrainsMonoNL Nerd Font"
    }
}