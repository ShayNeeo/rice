pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string text: "BAL"
    property string full: "balanced"
    property string profileName: "balanced"

    signal profileChanged(string profile)

    function cycle() {
        switch (full) {
            case "balanced": setProfile("performance"); break
            case "performance": setProfile("power-saver"); break
            default: setProfile("balanced"); break
        }
    }
    function setProfile(name)
    {
        setProc.command = ["powerprofilesctl", "set", name]
        setProc.running = true
        // Trigger theme switcher to apply matching quickshell theme
        themeProc.command = ["bash", "-c", "setsid -f ~/.local/bin/theme-switcher.sh " + name]
        themeProc.running = true
        root.profileChanged(name)
    }

    Process { id: setProc }
    Process { id: themeProc }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!getProfile.running)
                getProfile.running = true
        }
    }

    Process {
        id: getProfile
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                if (s) {
                    root.full = s
                    root.profileName = s
                    root.text = s.substring(0, 3).toUpperCase()
                    root.profileChanged(s)
                }
            }
        }
    }
}
