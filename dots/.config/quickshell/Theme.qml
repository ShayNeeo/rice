pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Background
    readonly property color bg: "#0f101b"
    readonly property color panelBg: "#0f101bdf"
    readonly property color surface: "#1c1e30"
    readonly property color surfaceHover: "#26283a"
    readonly property color border: "#2e3048"
    readonly property color borderAccent: Qt.rgba(0.31, 0.84, 1.0, 0.3)
    readonly property color accentFaint: Qt.rgba(0.31, 0.84, 1.0, 0.15)
    readonly property color accentMedium: Qt.rgba(0.31, 0.84, 1.0, 0.4)

    // Text
    readonly property color text: "#dde0f0"
    readonly property color textMuted: "#6a6e8a"
    readonly property color textDim: "#7a7e9a"
    readonly property color textInactive: "#5a5e7a"

    // Accents
    readonly property color cyan: "#4fd6ff"
    readonly property color cyanFaint: Qt.rgba(0.31, 0.84, 1.0, 0.2)
    readonly property color yellow: "#ffcc66"
    readonly property color yellowFaint: Qt.rgba(1.0, 0.8, 0.4, 0.3)
    readonly property color green: "#9ee8b8"
    readonly property color greenFaint: Qt.rgba(0.6, 0.91, 0.72, 0.2)
    readonly property color red: "#ff6b6b"
    readonly property color redFaint: Qt.rgba(1.0, 0.42, 0.42, 0.2)
    readonly property color purple: "#cdb7ff"
    readonly property color purpleFaint: Qt.rgba(0.8, 0.72, 1.0, 0.2)
    readonly property color blue: "#7ec8ff"
    readonly property color blueFaint: Qt.rgba(0.5, 0.78, 1.0, 0.25)
    readonly property color teal: "#7ee0c0"
    readonly property color orange: "#e0c0a0"
    readonly property color pink: "#a0b8ff"
    readonly property color pinkFaint: Qt.rgba(0.63, 0.72, 1.0, 0.2)

    // Bar
    readonly property int barHeight: 38
    readonly property int pillRadius: 10
    readonly property int pillHeight: 28
    readonly property int wsRadius: 8
    readonly property int wsHeight: 26
    
    // Animation
    readonly property int animationDuration: 200
    readonly property var easingType: Easing.InOutQuad
}
