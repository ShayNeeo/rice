pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services" as Svc
import "../../Theme.qml" as Theme

ColumnLayout {
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Notifications"
        font.pixelSize: 11
        font.weight: Font.Bold
        font.family: "JetBrainsMonoNL Nerd Font"
        color: Theme.cyan
    }
    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        clip: true
        model: Svc.NotifStatus.activeNotifications
        delegate: Rectangle {
            width: parent.width
            height: 36
            color: index % 2 === 0 ? Theme.surface : Theme.bg
            border.width: 1
            border.color: Theme.border
            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 6
                Text {
                    text: modelData.appName || "App"
                    font.pixelSize: 9
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: Theme.textMuted
                    Layout.maximumWidth: 60
                    elide: Text.ElideRight
                }
                Text {
                    text: modelData.summary || ""
                    font.pixelSize: 10
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: Theme.text
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
    }
}
