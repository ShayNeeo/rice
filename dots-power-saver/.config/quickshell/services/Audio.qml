
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool ready: false
    property bool muted: false
    property real volume: 0
    readonly property int percentage: Math.round(volume * 100)
    readonly property int percent: percentage

    function toggleMute() {
        muteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        muteProc.running = true
    }

    function openControl() {
        pavuProc.command = ["pavucontrol"]
        pavuProc.running = true
    }

    Process { id: muteProc }
    Process { id: pavuProc }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!getVol.running)
                getVol.running = true
        }
    }

    Process {
        id: getVol
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                const m = s.match(/Volume:\s*([0-9.]+)/)
                if (m) {
                    const v = parseFloat(m[1])
                    if (!isNaN(v)) {
                        root.ready = true
                        root.volume = Math.max(0, Math.min(1.5, v))
                    }
                }
                root.muted = /\[MUTED\]/.test(s)
            }
        }
    }
}
