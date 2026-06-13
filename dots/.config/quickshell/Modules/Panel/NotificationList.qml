pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services" as Svc

ColumnLayout {
    Layout.fillWidth: true
    spacing: 10

    property string cyan: "#4fd6ff"
    property string surface: "#1c1e30"
    property string border: "#2e3048"
    property string textColor: "#dde0f0"
    property string textMuted: "#6a6e8a"
    property string textDim: "#7a7e9a"
    property string textInactive: "#5a5e7a"

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Notifications (" + Svc.NotifStatus.count + ")"
            font.pixelSize: 11
            font.weight: Font.Bold
            font.family: "JetBrainsMonoNL Nerd Font"
            color: cyan
            Layout.fillWidth: true
        }
        Text {
            text: "Clear All"
            font.pixelSize: 9
            font.family: "JetBrainsMonoNL Nerd Font"
            color: textMuted
            visible: Svc.NotifStatus.count > 0

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Svc.NotifStatus.dismissAll()
            }
        }
    }

    ListView {
        id: notifList
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(Svc.NotifStatus.count * 50, 200)
        clip: true
        model: Svc.NotifStatus.activeNotifications
        spacing: 6

        delegate: Rectangle {
            id: notifItem
            required property var modelData
            required property int index

            width: notifList.width
            height: 44
            color: surface
            radius: 8
            border.width: 1
            border.color: border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                Rectangle {
                    width: 28; height: 28
                    radius: 14
                    color: "#4fd6ff26"
                    Text {
                        anchors.centerIn: parent
                        text: "\uDB80\uDE9F"
                        font.pixelSize: 14
                        color: cyan
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: modelData.appName || "Notification"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.family: "JetBrainsMonoNL Nerd Font"
                        color: textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: modelData.summary || ""
                        font.pixelSize: 10
                        font.family: "JetBrainsMonoNL Nerd Font"
                        color: textColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: "\u2715"
                    font.pixelSize: 10
                    color: textDim
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Svc.NotifStatus.removeNotification(modelData)
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: Svc.NotifStatus.count === 0
            text: "No new notifications"
            font.pixelSize: 10
            font.family: "JetBrainsMonoNL Nerd Font"
            color: textInactive
        }
    }
}
