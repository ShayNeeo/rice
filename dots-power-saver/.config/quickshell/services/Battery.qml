
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool present: false
    property int level: 0
    property bool charging: false
    property bool warning: level <= 30 && level > 15 && !charging
    property bool critical: level <= 15 && !charging

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!getBat.running)
                getBat.running = true
        }
    }

    Process {
        id: getBat
        command: ["sh", "-c",
            "bat=/sys/class/power_supply/BAT0; " +
            "[ -d \"$bat\" ] || bat=/sys/class/power_supply/BAT1; " +
            "[ -d \"$bat\" ] || { echo 'none'; exit 0; }; " +
            "cap=$(cat \"$bat/capacity\" 2>/dev/null || echo 0); " +
            "status=$(cat \"$bat/status\" 2>/dev/null || echo Unknown); " +
            "echo \"$cap $status\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                if (s === "none") {
                    root.present = false
                    return
                }
                const parts = s.split(" ")
                const cap = parseInt(parts[0])
                const status = parts[1]
                if (!isNaN(cap)) {
                    root.present = true
                    root.level = cap
                    root.charging = (status === "Charging" || status === "Full")
                }
            }
        }
    }
}
