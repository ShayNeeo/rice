pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

QtObject {
    id: root

    // Background — power-saver: slightly darker, no alpha blending
    readonly property color bg: "#0e0f18"
    readonly property color surface: "#161824"
    readonly property color surfaceHover: "#1e2030"
    readonly property color border: "#222430"
    readonly property color borderAccent: "#222430"

    // Text
    readonly property color text: "#c0c4d8"
    readonly property color textMuted: "#6a6e88"
    readonly property color textDim: "#5a5e78"

    // Accents — muted for power-saver
    readonly property color cyan: "#4fd6ff"
    readonly property color yellow: "#d4b070"
    readonly property color green: "#7ec8a0"
    readonly property color red: "#d06060"
    readonly property color purple: "#b0a0d0"
    readonly property color blue: "#70a8d0"
    readonly property color teal: "#60b090"
    readonly property color orange: "#c0a080"
    readonly property color pink: "#90a0d0"

    // Bar — smaller, zero rounding
    readonly property int barHeight: 30
    readonly property int pillRadius: 0
    readonly property int pillHeight: 22
    readonly property int wsRadius: 0
    readonly property int wsHeight: 22
}
