pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Theme.qml" as Theme

ColumnLayout {
    Layout.fillWidth: true
    spacing: 8

    property date currentDate: new Date()

    Text {
        text: "Calendar"
        font.pixelSize: 11
        font.weight: Font.Bold
        font.family: "JetBrainsMonoNL Nerd Font"
        color: Theme.cyan
    }
    
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        
        Rectangle {
            width: 24
            height: 24
            radius: 4
            color: mouseAreaPrev.containsMouse ? Theme.surfaceHover : Theme.surface
            border.width: 1
            border.color: Theme.border
            
            Text {
                anchors.centerIn: parent
                text: "◀"
                font.pixelSize: 10
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.cyan
            }
            
            MouseArea {
                id: mouseAreaPrev
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1)
                }
            }
        }
        
        Text {
            text: Qt.formatDate(currentDate, "MMMM yyyy")
            font.pixelSize: 11
            font.weight: Font.Bold
            font.family: "JetBrainsMonoNL Nerd Font"
            color: Theme.text
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
        
        Rectangle {
            width: 24
            height: 24
            radius: 4
            color: mouseAreaNext.containsMouse ? Theme.surfaceHover : Theme.surface
            border.width: 1
            border.color: Theme.border
            
            Text {
                anchors.centerIn: parent
                text: "▶"
                font.pixelSize: 10
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.cyan
            }
            
            MouseArea {
                id: mouseAreaNext
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1)
                }
            }
        }
    }
    
    GridLayout {
        id: calendarGrid
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: 7
            Text {
                text: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"][index]
                font.pixelSize: 9
                font.weight: Font.Bold
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.cyan
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
                border.color: isToday ? Theme.cyan : (isCurrentMonth ? Theme.border : Theme.border)
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
                
                function getDayNumber(idx) {
                    return idx - firstDay + 1
                }
                
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        var dayNum = parent.getDayNumber(parent.index)
                        return (parent.index >= parent.firstDay && dayNum >= 1 && dayNum <= parent.daysInMonth) ? dayNum.toString() : ""
                    }
                    font.pixelSize: 9
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                    font.family: "JetBrainsMonoNL Nerd Font"
                    color: parent.isCurrentMonth ? (parent.isToday ? Theme.cyan : Theme.text) : Theme.textMuted
                }
            }
        }
    }
}
