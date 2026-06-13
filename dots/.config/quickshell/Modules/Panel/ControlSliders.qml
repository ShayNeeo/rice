pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../services" as Svc

ColumnLayout {
    Layout.fillWidth: true
    spacing: 16

    property string cyan: "#4fd6ff"
    property string blue: "#7ec8ff"
    property string yellow: "#ffcc66"
    property string surface: "#1c1e30"
    property string surfaceHover: "#26283a"
    property string border: "#2e3048"
    property string bg: "#0f101b"
    property string textColor: "#dde0f0"
    property string textMuted: "#6a6e8a"

    // Audio
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            text: "Audio"
            font.pixelSize: 11
            font.weight: Font.Bold
            font.family: "JetBrainsMonoNL Nerd Font"
            color: cyan
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: Svc.Audio.muted ? "\uDB80\uDDDF" : "\uDB80\uDD7E"
                font.pixelSize: 14
                font.family: "JetBrainsMonoNL Nerd Font"
                color: blue

                MouseArea {
                    anchors.fill: parent
                    onClicked: Svc.Audio.toggleMute()
                }
            }
            Slider {
                id: volSlider
                Layout.fillWidth: true
                value: Svc.Audio.percent / 100
                onValueChanged: {
                    if (Math.abs(value * 100 - Svc.Audio.percent) > 1)
                        Svc.Audio.setVolume(Math.round(value * 100))
                }

                background: Rectangle {
                    implicitHeight: 6
                    color: border
                    radius: 3
                    Rectangle {
                        width: volSlider.visualPosition * parent.width
                        height: parent.height
                        color: blue
                        radius: 3
                    }
                }

                handle: Rectangle {
                    x: volSlider.visualPosition * (volSlider.width - width)
                    y: (volSlider.height - height) / 2
                    width: 14; height: 14
                    radius: 7
                    color: textColor
                    border.color: bg
                    border.width: 2
                }
            }
            Text {
                text: Svc.Audio.percent + "%"
                font.pixelSize: 10
                font.family: "JetBrainsMonoNL Nerd Font"
                color: textMuted
                Layout.preferredWidth: 25
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(Svc.Audio.sinks.length * 24, 100)
            contentWidth: -1
            clip: true

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 2

                Repeater {
                    model: Svc.Audio.sinks
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 22
                        radius: 4
                        color: modelData.active ? "#4fd6ff26" : (sinkMouse.containsMouse ? surfaceHover : "transparent")
                        border.width: modelData.active ? 1 : 0
                        border.color: cyan

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 6
                            Text {
                                text: modelData.active ? "\uDB80\uDD03" : "\uDB80\uDD04"
                                font.pixelSize: 10
                                font.family: "JetBrainsMonoNL Nerd Font"
                                color: modelData.active ? cyan : textMuted
                            }
                            Text {
                                text: modelData.name
                                font.pixelSize: 9
                                font.family: "JetBrainsMonoNL Nerd Font"
                                color: modelData.active ? textColor : textMuted
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: sinkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Audio.setSink(modelData.id)
                        }
                    }
                }
            }
        }
    }

    // Brightness
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            text: "Brightness"
            font.pixelSize: 11
            font.weight: Font.Bold
            font.family: "JetBrainsMonoNL Nerd Font"
            color: cyan
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: "\uDB80\uCC22"
                font.pixelSize: 14
                font.family: "JetBrainsMonoNL Nerd Font"
                color: yellow
            }
            Slider {
                id: brightSlider
                Layout.fillWidth: true
                value: Svc.Brightness.brightness
                onValueChanged: {
                    if (Math.abs(value - Svc.Brightness.brightness) > 0.01)
                        Svc.Brightness.setBrightness(value)
                }

                background: Rectangle {
                    implicitHeight: 6
                    color: border
                    radius: 3
                    Rectangle {
                        width: brightSlider.visualPosition * parent.width
                        height: parent.height
                        color: yellow
                        radius: 3
                    }
                }

                handle: Rectangle {
                    x: brightSlider.visualPosition * (brightSlider.width - width)
                    y: (brightSlider.height - height) / 2
                    width: 14; height: 14
                    radius: 7
                    color: textColor
                    border.color: bg
                    border.width: 2
                }
            }
            Text {
                text: Math.round(Svc.Brightness.brightness * 100) + "%"
                font.pixelSize: 10
                font.family: "JetBrainsMonoNL Nerd Font"
                color: textMuted
                Layout.preferredWidth: 25
            }
        }
    }

    // Quick Access
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: Svc.Warp.connected ? "#4fd6ff26" : surface
            radius: 10
            border.width: 1
            border.color: Svc.Warp.connected ? cyan : border

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    text: "\uDB80\uDD69"
                    color: Svc.Warp.connected ? cyan : textColor
                    font.pixelSize: 14
                    font.family: "JetBrainsMonoNL Nerd Font"
                    Layout.alignment: Qt.AlignCenter
                }
                Text {
                    text: "Warp"
                    color: textMuted
                    font.pixelSize: 9
                    font.family: "JetBrainsMonoNL Nerd Font"
                    Layout.alignment: Qt.AlignCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Svc.Warp.toggle()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: surface
            radius: 10
            border.width: 1
            border.color: border

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    text: "\uDB80\uDD0E"
                    color: textColor
                    font.pixelSize: 14
                    font.family: "JetBrainsMonoNL Nerd Font"
                    Layout.alignment: Qt.AlignCenter
                }
                Text {
                    text: "Pavu"
                    color: textMuted
                    font.pixelSize: 9
                    font.family: "JetBrainsMonoNL Nerd Font"
                    Layout.alignment: Qt.AlignCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Svc.Audio.openControl()
            }
        }
    }
}
