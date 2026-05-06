pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int active: 1

    function switchTo(id) {
        switchProc.command = ["hyprctl", "dispatch", "workspace", id.toString()]
        switchProc.running = true
    }

    Process {
        id: switchProc
    }

    // Poll active workspace — 200ms for snappy live feedback
    Timer {
        interval: 200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!getWs.running)
                getWs.running = true
        }
    }

    Process {
        id: getWs
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    if (data && data.id !== undefined) {
                        root.active = data.id
                    }
                } catch (e) {}
            }
        }
    }
}
