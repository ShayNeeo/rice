pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    spacing: 12
    Layout.fillWidth: true

    Text {
        text: "Controls"
        color: Theme.text
        font.bold: true
    }

    // Brightness
    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true
        
        RowLayout {
            Text { text: "Brightness"; color: Theme.textMuted; Layout.fillWidth: true }
            Text { text: Math.round(Svc.Brightness.brightness * 100) + "%"; color: Theme.textMuted }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 6
            color: Theme.border
            radius: 3
            
            Rectangle {
                width: parent.width * Svc.Brightness.brightness
                height: parent.height
                color: Theme.cyan
                radius: 3
                
                Behavior on width { NumberAnimation { duration: 100 } }
            }
            
            MouseArea {
                anchors.fill: parent
                onPositionChanged: (mouse) => {
                    Svc.Brightness.setBrightness(mouse.x / parent.width)
                }
                onPressed: (mouse) => {
                    Svc.Brightness.setBrightness(mouse.x / parent.width)
                }
            }
        }
    }

    // Volume
    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true
        
        RowLayout {
            Text { text: "Volume"; color: Theme.textMuted; Layout.fillWidth: true }
            Text { text: Svc.Audio.percentage + "%"; color: Theme.textMuted }
        }
        
        RowLayout {
            spacing: 8
            Layout.fillWidth: true
            
            Rectangle {
                Layout.fillWidth: true
                height: 6
                color: Theme.border
                radius: 3
                
                Rectangle {
                    width: parent.width * (Svc.Audio.volume / 1.5) // Max volume is 1.5
                    height: parent.height
                    color: Theme.blue
                    radius: 3
                    
                    Behavior on width { NumberAnimation { duration: 100 } }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onPositionChanged: (mouse) => {
                        Svc.Audio.setVolume((mouse.x / parent.width) * 150)
                    }
                    onPressed: (mouse) => {
                        Svc.Audio.setVolume((mouse.x / parent.width) * 150)
                    }
                }
            }
            
            Rectangle {
                width: 32
                height: 32
                color: Svc.Audio.muted ? Theme.red : Theme.surface
                radius: Theme.pillRadius / 2
                border.color: Theme.border
                
                Text {
                    anchors.centerIn: parent
                    text: Svc.Audio.muted ? "󰝟" : "󰕾"
                    color: Theme.text
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: Svc.Audio.toggleMute()
                }
            }
        }
    }

    // Quick Access
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        
        Rectangle {
            width: 60
            height: 40
            color: Svc.Warp.connected ? Theme.surfaceHover : Theme.surface
            radius: Theme.pillRadius
            border.color: Svc.Warp.connected ? Theme.cyan : Theme.border
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    text: "󰖩"
                    color: Svc.Warp.connected ? Theme.cyan : Theme.text
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignCenter
                }
                Text {
                    text: "Warp"
                    color: Theme.textMuted
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignCenter
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: Svc.Warp.toggle()
            }
        }
        
        Rectangle {
            width: 60
            height: 40
            color: Theme.surface
            radius: Theme.pillRadius
            border.color: Theme.border
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    text: "󰓎"
                    color: Theme.text
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignCenter
                }
                Text {
                    text: "Audio"
                    color: Theme.textMuted
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignCenter
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: Svc.Audio.openControl()
            }
        }
    }
}
