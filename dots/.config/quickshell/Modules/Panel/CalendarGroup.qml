pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    spacing: 8
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        
        Rectangle {
            width: 32
            height: 32
            color: Theme.surface
            radius: Theme.pillRadius / 2
            border.color: Theme.border
            Text {
                anchors.centerIn: parent
                text: "󰁕"
                color: Theme.text
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    let d = new Date(currentDate)
                    d.setMonth(d.getMonth() - 1)
                    currentDate = d
                }
            }
        }

        Text {
            text: Qt.formatDate(currentDate, "MMMM yyyy")
            color: Theme.text
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            width: 32
            height: 32
            color: Theme.surface
            radius: Theme.pillRadius / 2
            border.color: Theme.border
            Text {
                anchors.centerIn: parent
                text: "󰁔"
                color: Theme.text
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    let d = new Date(currentDate)
                    d.setMonth(d.getMonth() + 1)
                    currentDate = d
                }
            }
        }
    }

    GridLayout {
        columns: 7
        columnSpacing: 4
        rowSpacing: 4
        Layout.fillWidth: true

        Repeater {
            model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            Text {
                text: modelData
                color: Theme.textMuted
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        Repeater {
            model: calendarModel.days
            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                color: modelData.isToday ? Theme.cyan : (modelData.isCurrentMonth ? Theme.surface : Theme.bg)
                radius: 4
                border.color: modelData.isToday ? "transparent" : Theme.border
                
                Text {
                    anchors.centerIn: parent
                    text: modelData.day
                    color: modelData.isToday ? Theme.bg : (modelData.isCurrentMonth ? Theme.text : Theme.textMuted)
                    font.pixelSize: 12
                }
            }
        }
    }

    property date currentDate: new Date()
    onCurrentDateChanged: calendarModel.updateDays()

    QtObject {
        id: calendarModel
        property var days: []
        
        function updateDays() {
            let days = []
            let year = currentDate.getFullYear()
            let month = currentDate.getMonth()
            
            let firstDay = new Date(year, month, 1).getDay()
            let lastDate = new Date(year, month + 1, 0).getDate()
            let prevLastDate = new Date(year, month, 0).getDate()
            
            let today = new Date()
            
            // Previous month days
            for (let i = firstDay - 1; i >= 0; i--) {
                days.push({ day: (prevLastDate - i).toString(), isCurrentMonth: false, isToday: false })
            }
            
            // Current month days
            for (let i = 1; i <= lastDate; i++) {
                let isToday = (i === today.getDate() && month === today.getMonth() && year === today.getFullYear())
                days.push({ day: i.toString(), isCurrentMonth: true, isToday: isToday })
            }
            
            // Next month days to fill 6 rows
            let totalDays = days.length
            let remaining = 42 - totalDays
            for (let i = 1; i <= remaining; i++) {
                days.push({ day: i.toString(), isCurrentMonth: false, isToday: false })
            }
            
            calendarModel.days = days
        }
        
        Component.onCompleted: updateDays()
    }

    // Remove the Connections block
}
