pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string text: "--"

    function toggle() {
        toggleProc.command = ["fcitx5-remote", "-t"]
        toggleProc.running = true
    }

    Process { id: toggleProc }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!getStatus.running)
                getStatus.running = true
        }
    }

    Process {
        id: getStatus
        command: ["sh", "-c", "STATUS=$(fcitx5-remote 2>/dev/null); case \"$STATUS\" in 1) echo EN ;; 2) echo VI ;; *) echo -- ;; esac"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                if (s) root.text = s
            }
        }
    }
}
