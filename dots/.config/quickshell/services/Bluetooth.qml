pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property int deviceCount: 0
    property string icon: enabled && deviceCount > 0 ? "󰂯" : (enabled ? "󰂎" : "󰂔")

    function openManager() {
        openProc.command = ["blueman-manager"]
        openProc.running = true
    }

    Process { id: openProc }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!getStatus.running)
                getStatus.running = true
            if (!getDevices.running)
                getDevices.running = true
        }
    }

    Process {
        id: getStatus
        command: ["systemctl", "is-active", "bluetooth"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = (text.trim() === "active")
            }
        }
    }

    Process {
        id: getDevices
        command: ["sh", "-c", "bluetoothctl devices Connected 2>/dev/null | grep -c '^Device' || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim())
                root.deviceCount = isNaN(n) ? 0 : n
            }
        }
    }
}
