import QtQuick 2.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#2D2D2D"

    // Background Image
    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        smooth: false
    }

    // Clock
    Text {
        anchors.top: parent.top
        anchors.topMargin: 60
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(new Date(), "HH:mm:ss")
        font.family: "Terminus"
        font.pixelSize: 48
        font.bold: true
        color: "#D9895B"
        
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: parent.text = Qt.formatTime(new Date(), "HH:mm:ss")
        }
    }

    // Date
    Text {
        anchors.top: parent.top
        anchors.topMargin: 120
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(new Date(), "dddd, MMMM dd, yyyy")
        font.family: "Terminus"
        font.pixelSize: 16
        font.bold: true
        color: "#46658C"
    }

    // Login Box
    Rectangle {
        id: loginBox
        anchors.centerIn: parent
        width: 400
        height: 300
        color: "#3A3A3A"
        border.color: "#46658C"
        border.width: 2

        Column {
            anchors.centerIn: parent
            spacing: 20
            width: parent.width - 60

            // Title
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "PIXEL RICE"
                font.family: "Terminus"
                font.pixelSize: 18
                font.bold: true
                color: "#46658C"
            }

            // Username
            Rectangle {
                width: parent.width
                height: 40
                color: "#2D2D2D"
                border.color: usernameInput.activeFocus ? "#D9895B" : "#46658C"
                border.width: 2

                TextInput {
                    id: usernameInput
                    anchors.fill: parent
                    anchors.margins: 10
                    font.family: "Terminus"
                    font.pixelSize: 14
                    color: "#F2E9E9"
                    selectionColor: "#46658C"
                    selectedTextColor: "#F2E9E9"
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

            // Password
            Rectangle {
                width: parent.width
                height: 40
                color: "#2D2D2D"
                border.color: passwordInput.activeFocus ? "#D9895B" : "#46658C"
                border.width: 2

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: 10
                    font.family: "Terminus"
                    font.pixelSize: 14
                    color: "#F2E9E9"
                    echoMode: TextInput.Password
                    selectionColor: "#46658C"
                    selectedTextColor: "#F2E9E9"
                    verticalAlignment: TextInput.AlignVCenter
                    
                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            loginAction()
                            event.accepted = true
                        }
                    }
                }
            }

            // Session Dropdown - Simplified
            Row {
                width: parent.width
                height: 40
                spacing: 10

                Text {
                    width: 80
                    height: parent.height
                    text: "Session:"
                    font.family: "Terminus"
                    font.pixelSize: 14
                    color: "#F2E9E9"
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: parent.width - 90
                    height: parent.height
                    color: "#4A4A4A"
                    border.color: "#D9895B"
                    border.width: 1

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        text: sessionModel.data(sessionModel.index(sessionComboIndex, 0), Qt.DisplayRole) || "Hyprland"
                        font.family: "Terminus"
                        font.pixelSize: 14
                        color: "#F2E9E9"
                        verticalAlignment: Text.AlignVCenter
                    }

                    property int sessionComboIndex: sessionModel.lastIndex

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // Cycle through sessions
                            var newIndex = (parent.sessionComboIndex + 1) % sessionModel.rowCount()
                            parent.sessionComboIndex = newIndex
                        }
                    }
                }
            }

            // Login Button
            Rectangle {
                width: parent.width
                height: 45
                color: loginMouseArea.pressed ? "#D9895B" : (loginMouseArea.containsMouse ? "#5A7FA8" : "#46658C")
                border.color: "#46658C"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "LOGIN"
                    font.family: "Terminus"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#F2E9E9"
                }

                MouseArea {
                    id: loginMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: loginAction()
                }
            }

            // Error Message
            Text {
                id: errorText
                width: parent.width
                height: 20
                text: ""
                font.family: "Terminus"
                font.pixelSize: 12
                color: "#D9895B"
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
            }
        }
    }

    // Power Buttons
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 30
        spacing: 15

        // Reboot
        Rectangle {
            width: 50
            height: 50
            color: rebootMouseArea.pressed ? "#D9895B" : (rebootMouseArea.containsMouse ? "#E5A174" : "#BFADA8")
            border.color: "#BFADA8"
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: "⟳"
                font.pixelSize: 24
                font.bold: true
                color: "#2D2D2D"
            }

            MouseArea {
                id: rebootMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.reboot()
            }
        }

        // Shutdown
        Rectangle {
            width: 50
            height: 50
            color: shutdownMouseArea.pressed ? "#D9895B" : (shutdownMouseArea.containsMouse ? "#E5A174" : "#BFADA8")
            border.color: "#BFADA8"
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: "⏻"
                font.pixelSize: 24
                font.bold: true
                color: "#2D2D2D"
            }

            MouseArea {
                id: shutdownMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.powerOff()
            }
        }
    }

    // Error Clear Timer
    Timer {
        id: errorTimer
        interval: 3000
        repeat: false
        onTriggered: errorText.text = ""
    }

    // Functions
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
