pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false
    property string label: ""
    property int signal: 0

    function openManager() {
        openProc.command = ["nm-connection-editor"]
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
        }
    }

    Process {
        id: getStatus
        command: ["bash", "-c",
            "nmcli -t -f STATE d 2>/dev/null | head -1"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim()
                if (state === "connected" || state === "connected (site-only)") {
                    root.connected = true
                    getWifi.running = true
                } else {
                    root.connected = false
                    root.label = ""
                    root.signal = 0
                }
            }
        }
    }

    Process {
        id: getWifi
        command: ["bash", "-c",
            "nmcli -t -f ACTIVE,SSID,SIGNAL d wifi 2>/dev/null | grep '^yes:'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim()
                if (line) {
                    const parts = line.split(":")
                    if (parts.length >= 3) {
                        const name = parts[1] || ""
                        root.label = name.length > 12 ? name.substring(0, 12) : name
                        const sig = parseInt(parts[2]) || 0
                        root.signal = sig
                    }
                } else {
                    root.label = "eth"
                    root.signal = 0
                }
            }
        }
    }
}
