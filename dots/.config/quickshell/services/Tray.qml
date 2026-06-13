pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var apps: []

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!getApps.running)
                getApps.running = true
        }
    }

    Process {
        id: getApps
        command: ["sh", "-c", 
            "for proc in nm-applet blueman-applet discord slack telegram-desktop steam spotify obs; do " +
            "pgrep -x \"$proc\" > /dev/null && echo \"$proc\"; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                root.apps = lines
            }
        }
    }
}
