
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false
    property string label: ""

    function openManager() {
        openProc.command = ["nm-connection-editor"]
        openProc.running = true
    }

    Process { id: openProc }

    Timer {
        interval: 30000
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
        command: ["sh", "-c",
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
                }
            }
        }
    }

    Process {
        id: getWifi
        command: ["sh", "-c",
            "nmcli -t -f ACTIVE,SSID d wifi 2>/dev/null | grep '^yes:' | cut -d: -f2"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim()
                if (name) {
                    root.label = name.length > 12 ? name.substring(0, 12) + "…" : name
                } else {
                    root.label = "eth"
                }
            }
        }
    }
}
