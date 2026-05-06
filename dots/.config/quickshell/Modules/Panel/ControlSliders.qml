pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../services" as Svc
import "../../Theme.qml" as Theme

ColumnLayout {
    Layout.fillWidth: true
    spacing: 16

    // Audio
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        Text {
            text: "Audio"
            font.pixelSize: 11
            font.weight: Font.Bold
            font.family: "JetBrainsMonoNL Nerd Font"
            color: Theme.cyan
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: ""
                font.pixelSize: 12
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.blue
            }
            Slider {
                id: volSlider
                Layout.fillWidth: true
                value: Svc.Audio.percent / 100
                onValueChanged: {
                    if (Math.abs(value * 100 - Svc.Audio.percent) > 1) {
                        Svc.Audio.setVolume(Math.round(value * 100))
                    }
                }
                
                background: Rectangle {
                    implicitHeight: 4
                    color: volSlider.pressed ? Theme.borderAccent : Theme.border
                    radius: 2
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        width: volSlider.visualPosition * parent.width
                        height: parent.height
                        color: volSlider.pressed ? Theme.cyan : Theme.blue
                        radius: 2
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
                
                handle: Rectangle {
                    x: volSlider.visualPosition * (volSlider.width - width)
                    y: (volSlider.height - height) / 2
                    width: 12; height: 12
                    radius: 6
                    color: volSlider.pressed ? Theme.cyan : Theme.text
                    border.color: Theme.bg
                    border.width: 2
                    
                    scale: volSlider.pressed ? 1.2 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }
            Text {
                text: Svc.Audio.percent + "%"
                font.pixelSize: 10
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.textMuted
            }
        }
    }

    // Brightness
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        Text {
            text: "Brightness"
            font.pixelSize: 11
            font.weight: Font.Bold
            font.family: "JetBrainsMonoNL Nerd Font"
            color: Theme.cyan
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: "󰌢"
                font.pixelSize: 12
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.yellow
            }
            Slider {
                id: brightSlider
                Layout.fillWidth: true
                value: Svc.Brightness.brightness
                onValueChanged: {
                    if (Math.abs(value - Svc.Brightness.brightness) > 0.01) {
                        Svc.Brightness.setBrightness(value)
                    }
                }
                
                background: Rectangle {
                    implicitHeight: 4
                    color: brightSlider.pressed ? Theme.borderAccent : Theme.border
                    radius: 2
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        width: brightSlider.visualPosition * parent.width
                        height: parent.height
                        color: brightSlider.pressed ? Theme.cyan : Theme.yellow
                        radius: 2
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
                
                handle: Rectangle {
                    x: brightSlider.visualPosition * (brightSlider.width - width)
                    y: (brightSlider.height - height) / 2
                    width: 12; height: 12
                    radius: 6
                    color: brightSlider.pressed ? Theme.cyan : Theme.text
                    border.color: Theme.bg
                    border.width: 2
                    
                    scale: brightSlider.pressed ? 1.2 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }
            Text {
                text: Math.round(Svc.Brightness.brightness * 100) + "%"
                font.pixelSize: 10
                font.family: "JetBrainsMonoNL Nerd Font"
                color: Theme.textMuted
            }
        }
    }
}
