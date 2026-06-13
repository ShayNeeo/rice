pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications as NS
import "services" as Svc

ShellRoot {
    id: shellRoot

    property bool panelOpen: false

    function togglePanel() { panelOpen = !panelOpen }
    function closePanel() { panelOpen = false }

    NS.NotificationServer {
        id: notifServer
        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyMarkupSupported: true
        imageSupported: false
        persistenceSupported: false

        onNotification: notif => {
            notif.tracked = true
            Svc.NotifStatus.addNotification(notif)
        }
    }

    Bar {}
}
