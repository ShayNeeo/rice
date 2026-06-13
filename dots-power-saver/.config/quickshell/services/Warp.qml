
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false

    function toggle() {
        toggleProc.command = ["warp-nextdns-toggle.sh"]
        toggleProc.running = true
    }

    Process { id: toggleProc }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            if (!getStatus.running)
                getStatus.running = true
        }
    }

    Process {
        id: getStatus
        command: ["sh", "-c", "warp-cli status 2>/dev/null | grep -q Connected && echo 1 || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.connected = text.trim() === "1"
            }
        }
    }
}
