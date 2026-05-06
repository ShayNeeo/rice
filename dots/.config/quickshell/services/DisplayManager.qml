pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool externalConnected: false
    property string builtinDisplay: "eDP-1"
    property string externalDisplay: "HDMI-1"
    
    function updateDisplayStatus() {
        statusProc.command = ["bash", "-c",
            "output=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' | grep -v '^eDP'); " +
            "[ -n \"$output\" ] && echo 'yes' || echo 'no'"
        ]
        statusProc.running = true
    }
    
    function applyDisplayConfig() {
        if (externalConnected) {
            applyProc.command = ["bash", "-c",
                "hyprctl keyword monitor 'eDP-1,preferred,auto,1,mirror,HDMI-1' 2>/dev/null || " +
                "hyprctl keyword monitor 'eDP-1,disabled' 2>/dev/null"
            ]
        } else {
            applyProc.command = ["bash", "-c",
                "hyprctl keyword monitor 'eDP-1,preferred,auto,1' 2>/dev/null"
            ]
        }
        applyProc.running = true
    }
    
    Process { id: statusProc }
    Process { id: applyProc }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateDisplayStatus()
    }

    Connections {
        target: statusProc.stdout
        function onStreamFinished() {
            const result = statusProc.stdout.text.trim()
            const wasConnected = root.externalConnected
            root.externalConnected = (result === "yes")
            
            if (root.externalConnected !== wasConnected) {
                root.applyDisplayConfig()
            }
        }
    }
    
    Component.onCompleted: updateDisplayStatus()
}
