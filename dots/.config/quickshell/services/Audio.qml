pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool ready: false
    property bool muted: false
    property real volume: 0
    property var sinks: []
    property string currentSinkName: ""

    signal changed()

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

    function setVolume(percent) {
        const vol = Math.max(0, Math.min(100, percent)) / 100
        setProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", vol.toString()]
        setProc.running = true
    }

    function setSink(id) {
        sinkSwitchProc.command = ["wpctl", "set-default", id.toString()]
        sinkSwitchProc.running = true
    }

    Process { id: muteProc }
    Process { id: pavuProc }
    Process { id: setProc }
    Process { id: sinkSwitchProc }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!getVol.running) getVol.running = true
            if (!getSinks.running) getSinks.running = true
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
                        if (root.volume !== v) {
                            root.volume = Math.max(0, Math.min(1.5, v))
                            root.changed()
                        }
                    }
                }
                const isMuted = /\[MUTED\]/.test(s)
                if (root.muted !== isMuted) {
                    root.muted = isMuted
                    root.changed()
                }
            }
        }
    }

    Process {
        id: getSinks
        command: ["bash", "-c", "wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -v 'Sinks:' | grep -v 'Sources:' | grep '^  ' | sed 's/^[ *]*//'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                const parsedSinks = lines.map(line => {
                    const m = line.match(/^([0-9]+)\. (.*)/)
                    if (m) {
                        return { id: m[1], name: m[2], active: line.includes("*") }
                    }
                    return null
                }).filter(s => s !== null)

                root.sinks = parsedSinks
                const active = parsedSinks.find(s => s.active)
                if (active) root.currentSinkName = active.name
            }
        }
    }
}
