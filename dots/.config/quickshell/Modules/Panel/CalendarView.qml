pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    Layout.fillWidth: true
    spacing: 8

    property date currentDate: new Date()
    property string cyan: "#4fd6ff"
    property string surface: "#1c1e30"
    property string surfaceHover: "#26283a"
    property string border: "#2e3048"
    property string textColor: "#dde0f0"
    property string textMuted: "#6a6e8a"

    Text {
        text: "Calendar"
        font.pixelSize: 11
        font.weight: Font.Bold
        font.family: "JetBrainsMonoNL Nerd Font"
        color: cyan
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            width: 24
            height: 24
            radius: 4
            color: mouseAreaPrev.containsMouse ? surfaceHover : surface
            border.width: 1
            border.color: border

            Text {
                anchors.centerIn: parent
                text: "\u25C0"
                font.pixelSize: 10
                font.family: "JetBrainsMonoNL Nerd Font"
                color: cyan
            }

            MouseArea {
                id: mouseAreaPrev
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: { currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1) }
            }
        }

        Text {
            text: Qt.formatDate(currentDate, "MMMM yyyy")
            font.pixelSize: 11
            font.weight: Font.Bold
            font.family: "JetBrainsMonoNL Nerd Font"
            color: textColor
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            width: 24
            height: 24
            radius: 4
            color: mouseAreaNext.containsMouse ? surfaceHover : surface
            border.width: 1
            border.color: border

            Text {
                anchors.centerIn: parent
                text: "\u25B6"
                font.pixelSize: 10
                font.family: "JetBrainsMonoNL Nerd Font"
                color: cyan
            }

            MouseArea {
                id: mouseAreaNext
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: { currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1) }
            }
        }
    }

    GridLayout {
        columns: 7
        rowSpacing: 2
        columnSpacing: 2
        Layout.fillWidth: true

        Repeater {
            model: 7
            Text {
                required property int index
                text: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"][index]
                font.pixelSize: 9
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: cyan
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }
        Repeater {
            model: 42
            Rectangle {
                required property int index
                Layout.fillWidth: true
                height: 20
                color: "transparent"
                border.width: 1
                border.color: isToday ? cyan : border
                radius: 2

                property bool isToday: {
                    var today = new Date()
                    var dayNum = getDayNumber(index)
                    return dayNum > 0 && dayNum <= daysInMonth &&
                           today.getFullYear() === currentDate.getFullYear() &&
                           today.getMonth() === currentDate.getMonth() &&
                           today.getDate() === dayNum
                }

                property bool isCurrentMonth: {
                    var dayNum = getDayNumber(index)
                    return dayNum > 0 && dayNum <= daysInMonth
                }

                property int daysInMonth: new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0).getDate()
                property int firstDay: new Date(currentDate.getFullYear(), currentDate.getMonth(), 1).getDay()

                function getDayNumber(idx) { return idx - firstDay + 1 }

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: {
                        var dayNum = parent.getDayNumber(index)
                        return (index >= parent.firstDay && dayNum >= 1 && dayNum <= parent.daysInMonth) ? dayNum.toString() : ""
                    }
                    font.pixelSize: 9
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: parent.isCurrentMonth ? (parent.isToday ? cyan : textColor) : textMuted
                }
            }
        }
    }
}
