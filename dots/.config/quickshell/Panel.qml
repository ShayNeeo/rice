pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "Theme.qml" as Theme
import "Modules/Panel"

PanelWindow {
    id: root
    
    anchors {
        top: true
        right: true
    }
    
    WlrLayershell.namespace: "quickshell-panel"
    implicitWidth: 400
    implicitHeight: content.implicitHeight + 24
    
    color: Theme.panelBg
    
    visible: shellRoot.panelOpen
    
    Rectangle {
        anchors.fill: parent
        z: -1
        color: "transparent"
        border.width: 2
        border.color: Theme.accentFaint
        radius: 12
    }
    
    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 20
        
        NotificationList {
            id: notifList
            opacity: 0
            y: 20
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
        }
        
        ControlSliders {
            id: controls
            opacity: 0
            y: 20
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
        }
        
        CalendarView {
            id: calendar
            opacity: 0
            y: 20
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
        }
    }
    
    Component.onCompleted: {
        reveal()
    }
    
    onVisibleChanged: {
        if (visible) reveal()
    }
    
    function reveal() {
        notifList.opacity = 1; notifList.y = 0
        
        timerControls.start()
        timerCalendar.start()
    }
    
    Timer {
        id: timerControls
        interval: 100
        onTriggered: {
            controls.opacity = 1; controls.y = 0
        }
    }
    
    Timer {
        id: timerCalendar
        interval: 200
        onTriggered: {
            calendar.opacity = 1; calendar.y = 0
        }
    }
}
