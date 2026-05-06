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

    // Create one Bar per screen
    Bar {
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    Panel {
        id: panel
    }

    VolumeOSD {
        id: volumeOsd
    }

    BrightnessOSD {
        id: brightnessOsd
    }

    FnLockOSD {
        id: fnLockOsd
    }

    AirplaneModeOSD {
        id: airplaneModeOsd
    }

    Connections {
        target: Svc.Audio
        function onChanged() {
            volumeOsd.show()
        }
    }

    Connections {
        target: Svc.Brightness
        function onChanged() {
            brightnessOsd.show()
        }
    }
}
