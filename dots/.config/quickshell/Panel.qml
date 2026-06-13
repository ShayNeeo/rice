pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "Modules/Panel"

PanelWindow {
    id: root

    readonly property string panelBg: "#0f101bdf"
    readonly property string accentFaint: "#4fd6ff26"

    property real notifOffset: 20
    property real controlsOffset: 20
    property real calendarOffset: 20

    Behavior on notifOffset { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
    Behavior on controlsOffset { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
    Behavior on calendarOffset { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

    anchors {
        top: true
        right: true
    }

    WlrLayershell.namespace: "quickshell-panel"
    implicitWidth: 400
    implicitHeight: content.implicitHeight + 24
    color: panelBg

    visible: shellRoot.panelOpen

    Rectangle {
        anchors.fill: parent
        z: -1
        color: "transparent"
        border.width: 2
        border.color: accentFaint
        radius: 12
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 20

        NotificationList {
            id: notifList
            Layout.fillWidth: true
            opacity: 0
            transform: Translate { y: root.notifOffset }
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
        }

        ControlSliders {
            id: controls
            Layout.fillWidth: true
            opacity: 0
            transform: Translate { y: root.controlsOffset }
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
        }

        CalendarView {
            id: calendar
            Layout.fillWidth: true
            opacity: 0
            transform: Translate { y: root.calendarOffset }
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
        }
    }

    onVisibleChanged: {
        if (!visible) {
            root.notifOffset = 20
            root.controlsOffset = 20
            root.calendarOffset = 20
            notifList.opacity = 0
            controls.opacity = 0
            calendar.opacity = 0
            return
        }
        revealTimer.start()
    }

    Timer {
        id: revealTimer
        interval: 50
        onTriggered: {
            notifList.opacity = 1; root.notifOffset = 0
            controlsTimer.start()
        }
    }

    Timer {
        id: controlsTimer
        interval: 120
        onTriggered: {
            controls.opacity = 1; root.controlsOffset = 0
            calendarTimer.start()
        }
    }

    Timer {
        id: calendarTimer
        interval: 120
        onTriggered: {
            calendar.opacity = 1; root.calendarOffset = 0
        }
    }
}
