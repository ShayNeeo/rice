pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications as NS

Singleton {
    id: root

    property int count: 0
    property bool dnd: false
    property bool hasNotifs: count > 0 && !dnd

    // Latest notification data (for popup display)
    property string lastSummary: ""
    property string lastBody: ""
    property string lastAppName: ""
    property int notifVersion: 0  // increments on each new notification

    property string icon: {
        if (dnd) return "󰂠"
        if (count > 0) return "󰂞"
        return "󰂜"
    }

    property var activeNotifications: []

    function addNotification(notif) {
        let list = activeNotifications.slice()
        list.push(notif)
        activeNotifications = list
        count = activeNotifications.length

        // Store latest notification data
        lastSummary = notif.summary || ""
        lastBody = notif.body || ""
        lastAppName = notif.appName || ""
        notifVersion++

        // Auto-remove after 5 seconds
        var timer = autoRemoveTimer.createObject(root, { "target": notif })
        timer.start()
    }

    function removeNotification(notif) {
        let list = activeNotifications.filter(n => n !== notif)
        activeNotifications = list
        count = activeNotifications.length
    }

    function toggleDnd() {
        dnd = !dnd
    }

    function dismissAll() {
        activeNotifications.forEach(n => n.dismiss())
        activeNotifications = []
        count = 0
    }

    property Component autoRemoveTimer: Component {
        Timer {
            id: autoTimer
            property var target
            interval: 5000
            running: false
            repeat: false
            onTriggered: {
                root.removeNotification(target)
                autoTimer.destroy()
            }
        }
    }
}
