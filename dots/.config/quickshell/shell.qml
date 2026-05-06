pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications as NS
import "services" as Svc
import "Modules/Bar"

ShellRoot {
    id: shellRoot


    // State
    property bool dropdownOpen: false
    property bool panelOpen: false

    function toggleDropdown() {
        dropdownOpen = !dropdownOpen
    }

    function closeDropdown() {
        dropdownOpen = false
    }

    function togglePanel() {
        panelOpen = !panelOpen
    }

    function closePanel() {
        panelOpen = false
    }

    // Initialize display manager for external screen detection
    Component.onCompleted: {
        Svc.DisplayManager.updateDisplayStatus()
    }

    // Bar is created per-screen automatically by quickshell
    // when PanelWindow uses anchors.top/left/right
    Repeater {
        model: Quickshell.screens
        Loader {
            source: Svc.PowerProfile.full === "power-saver" ? "PowerSaverBar.qml" : "Bar.qml"
            onLoaded: item.screen = modelData
        }
    }

    Panel {
        id: panel
    }

    VolumeOSD {
        id: volumeOsd
    }

    Connections {
        target: Svc.Audio
        function onChanged() {
            volumeOsd.show()
        }
    }
}
