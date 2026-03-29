import QtQuick 2.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#151621"

    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        smooth: false
    }

    // Dim overlay — cartoon panel separation from wallpaper
    Rectangle {
        anchors.fill: parent
        color: "#151621"
        opacity: 0.35
    }

    Text {
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(new Date(), "HH:mm:ss")
        font.family: "JetBrains Mono"
        font.pixelSize: 44
        font.bold: true
        color: "#4fd6ff"

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: parent.text = Qt.formatTime(new Date(), "HH:mm:ss")
        }
    }

    Text {
        anchors.top: parent.top
        anchors.topMargin: 112
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(new Date(), "dddd, MMMM dd, yyyy")
        font.family: "JetBrains Mono"
        font.pixelSize: 15
        font.bold: true
        color: "#a0a2b8"
    }

    Rectangle {
        id: loginBox
        anchors.centerIn: parent
        width: 400
        height: 300
        radius: 6
        color: "#1e2030"
        border.color: "#4fd6ff"
        border.width: 2

        Column {
            anchors.centerIn: parent
            spacing: 20
            width: parent.width - 60

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "PIXEL RICE"
                font.family: "JetBrains Mono"
                font.pixelSize: 17
                font.bold: true
                color: "#ffcc66"
            }

            Rectangle {
                width: parent.width
                height: 40
                radius: 6
                color: "#151621"
                border.color: usernameInput.activeFocus ? "#4fd6ff" : "#2a2c3c"
                border.width: 2

                TextInput {
                    id: usernameInput
                    anchors.fill: parent
                    anchors.margins: 10
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    color: "#e0e2f0"
                    selectionColor: "#4fd6ff"
                    selectedTextColor: "#151621"
                    text: userModel.lastUser
                    verticalAlignment: TextInput.AlignVCenter
                    focus: true

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            passwordInput.forceActiveFocus()
                            event.accepted = true
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 40
                radius: 6
                color: "#151621"
                border.color: passwordInput.activeFocus ? "#4fd6ff" : "#2a2c3c"
                border.width: 2

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: 10
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    color: "#e0e2f0"
                    echoMode: TextInput.Password
                    selectionColor: "#4fd6ff"
                    selectedTextColor: "#151621"
                    verticalAlignment: TextInput.AlignVCenter

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            loginAction()
                            event.accepted = true
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 40
                spacing: 10

                Text {
                    width: 80
                    height: parent.height
                    text: "Session:"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    color: "#e0e2f0"
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: parent.width - 90
                    height: parent.height
                    radius: 6
                    color: "#26283a"
                    border.color: "#ffcc66"
                    border.width: 1

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        text: sessionModel.data(sessionModel.index(sessionComboIndex, 0), Qt.DisplayRole) || "Hyprland"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        color: "#e0e2f0"
                        verticalAlignment: Text.AlignVCenter
                    }

                    property int sessionComboIndex: sessionModel.lastIndex

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var newIndex = (parent.sessionComboIndex + 1) % sessionModel.rowCount()
                            parent.sessionComboIndex = newIndex
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 45
                radius: 6
                color: loginMouseArea.pressed ? "#4fd6ff" : (loginMouseArea.containsMouse ? "#26283a" : "#1e2030")
                border.color: "#4fd6ff"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "LOGIN"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    font.bold: true
                    color: loginMouseArea.pressed ? "#151621" : "#e0e2f0"
                }

                MouseArea {
                    id: loginMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: loginAction()
                }
            }

            Text {
                id: errorText
                width: parent.width
                height: 20
                text: ""
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: "#ff6b6b"
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
            }
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 30
        spacing: 12

        Rectangle {
            width: 52
            height: 52
            radius: 6
            color: rebootMouseArea.pressed ? "#4fd6ff" : (rebootMouseArea.containsMouse ? "#26283a" : "#1e2030")
            border.color: "#2a2c3c"
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: "\u21bb"
                font.pixelSize: 26
                font.bold: true
                font.family: "JetBrains Mono"
                color: rebootMouseArea.pressed ? "#151621" : "#ffcc66"
            }

            MouseArea {
                id: rebootMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.reboot()
            }
        }

        Rectangle {
            width: 52
            height: 52
            radius: 6
            color: shutdownMouseArea.pressed ? "#ff6b6b" : (shutdownMouseArea.containsMouse ? "#26283a" : "#1e2030")
            border.color: "#2a2c3c"
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: "\u23fc"
                font.pixelSize: 24
                font.bold: true
                font.family: "JetBrains Mono"
                color: shutdownMouseArea.pressed ? "#151621" : "#e0e2f0"
            }

            MouseArea {
                id: shutdownMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.powerOff()
            }
        }
    }

    Timer {
        id: errorTimer
        interval: 3000
        repeat: false
        onTriggered: errorText.text = ""
    }

    function loginAction() {
        var sessionIndex = loginBox.children[0].children[3].children[1].sessionComboIndex
        sddm.login(usernameInput.text, passwordInput.text, sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = "LOGIN FAILED!"
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
            errorTimer.restart()
        }
    }

    Component.onCompleted: {
        if (usernameInput.text === "")
            usernameInput.forceActiveFocus()
        else
            passwordInput.forceActiveFocus()
    }
}
