pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool externalConnected: false
    property string builtinDisplay: "eDP-1"
    property int screenCount: 1

    function updateDisplayStatus() {
        statusProc.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statusProc.running)
                statusProc.running = true
        }
    }

    Process {
        id: statusProc
        command: ["bash", "-c",
            "output=$(hyprctl monitors -j 2>/dev/null); " +
            "external=$(echo \"$output\" | jq -r '[.[].name] | map(select(. != \"eDP-1\")) | length'); " +
            "total=$(echo \"$output\" | jq -r '. | length'); " +
            "echo \"$external $total\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                if (parts.length >= 2) {
                    root.externalConnected = parseInt(parts[0]) > 0
                    root.screenCount = parseInt(parts[1]) || 1
                }
            }
        }
    }
}
