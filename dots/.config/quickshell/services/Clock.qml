pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property string time: ""
    property string date: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            root.time = Qt.formatTime(now, "HH:mm")
            root.date = Qt.formatDate(now, "dddd, MMMM d")
        }
    }
}
