import QtQuick
import QtQuick.Layouts
import Quickshell
import "services" as Svc

PanelWindow {
    id: barWindow;

    anchors {
        top: true;
        left: true;
        right: true;
    }

    implicitHeight: 50;
    color: "#ff00ff"; // BRIGHT PINK for visibility

    RowLayout {
        anchors.fill: parent;
        anchors.leftMargin: 10;
        anchors.rightMargin: 10;

        Text {
            text: "BAR VISIBLE? " + Svc.Clock.time;
            color: "#ffffff";
            font.pixelSize: 14;
            font.family: "JetBrainsMonoNL Nerd Font";
        }
    }
}
