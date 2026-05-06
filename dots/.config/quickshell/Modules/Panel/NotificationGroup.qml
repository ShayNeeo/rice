pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    spacing: 8
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Notifications"
            color: Theme.text
            font.bold: true
            Layout.fillWidth: true
        }
        
        Rectangle {
            width: 80
            height: 28
            color: Theme.surface
            radius: Theme.pillRadius
            border.color: Theme.border
            
            Text {
                anchors.centerIn: parent
                text: "Clear All"
                color: Theme.textMuted
                font.pixelSize: 12
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: Svc.NotifStatus.dismissAll()
            }
        }
    }

    ListView {
        id: notifList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: Svc.NotifStatus.activeNotifications
        spacing: 4

        delegate: Rectangle {
            width: notifList.width
            height: 40
            color: Theme.surface
            radius: Theme.pillRadius
            border.color: Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                Text {
                    text: modelData.appName || "Unknown"
                    color: Theme.cyan
                    font.bold: true
                    Layout.preferredWidth: 80
                }
                Text {
                    text: modelData.summary || ""
                    color: Theme.text
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                
                Rectangle {
                    width: 24
                    height: 24
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰅚"
                        color: Theme.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.dismiss()
                    }
                }
            }
        }
    }

    Text {
        text: "No notifications"
        color: Theme.textMuted
        anchors.centerIn: parent
        visible: Svc.NotifStatus.count === 0
    }
}
