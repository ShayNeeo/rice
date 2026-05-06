pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real brightness: 0.5
    property bool ready: false

    function setBrightness(value) {
        const v = Math.max(0.05, Math.min(1.0, value))
        setProc.command = ["brightnessctl", "set", Math.round(v * 100).toString() + "%"]
        setProc.running = true
    }

    function increase() {
        setBrightness(brightness + 0.05)
    }

    function decrease() {
        setBrightness(brightness - 0.05)
    }

    Process { id: setProc }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!getBright.running)
                getBright.running = true
        }
    }

    Process {
        id: getBright
        command: ["sh", "-c",
            "if command -v brightnessctl >/dev/null 2>&1; then " +
            "brightnessctl -m -d 'backlight' 2>/dev/null | grep -o '[0-9]*%' | tr -d '%' | awk '{print $1/100}'; " +
            "else " +
            "cat /sys/class/backlight/*/brightness 2>/dev/null | head -1 | awk '{print $1/100}'; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                if (s) {
                    const v = parseFloat(s)
                    if (!isNaN(v) && v >= 0) {
                        root.ready = true
                        root.brightness = Math.min(1.0, v)
                    }
                }
            }
        }
    }
}