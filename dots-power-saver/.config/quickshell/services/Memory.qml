
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string text: "--%"
    property real usage: 0

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!getMem.running)
                getMem.running = true
        }
    }

    Process {
        id: getMem
        command: ["sh", "-c",
            "total=$(awk '/^MemTotal/ {print $2}' /proc/meminfo); " +
            "avail=$(awk '/^MemAvailable/ {print $2}' /proc/meminfo); " +
            "if [ -n \"$total\" ] && [ -n \"$avail\" ] && [ \"$total\" -gt 0 ]; then " +
            "  pct=$(( (total - avail) * 100 / total )); " +
            "  echo \"${pct}%\"; " +
            "else " +
            "  echo \"--%\"; " +
            "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                if (s && s !== "--%") {
                    root.text = s
                    root.usage = parseInt(s) || 0
                }
            }
        }
    }
}
