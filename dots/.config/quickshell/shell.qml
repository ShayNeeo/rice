pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Svc
import "Modules/Bar"

ShellRoot {
    id: shellRoot

    property bool dropdownOpen: false
    property bool panelOpen: false

    function toggleDropdown() { dropdownOpen = !dropdownOpen }
    function closeDropdown() { dropdownOpen = false }
    function togglePanel() { panelOpen = !panelOpen }
    function closePanel() { panelOpen = false }

    Bar {
        screen: Quickshell.screens[0]
    }

    Bar {
        visible: Quickshell.screens.length > 1
        screen: Quickshell.screens.length > 1 ? Quickshell.screens[1] : null
    }

    Panel {
        visible: shellRoot.panelOpen
        screen: Quickshell.screens[0]
    }

    Panel {
        visible: shellRoot.panelOpen && Quickshell.screens.length > 1
        screen: Quickshell.screens.length > 1 ? Quickshell.screens[1] : null
    }

    VolumeOSD { id: volumeOsd }
    BrightnessOSD { id: brightnessOsd }
    FnLockOSD { id: fnLockOsd }
    AirplaneModeOSD { id: airplaneModeOsd }

    Connections {
        target: Svc.Audio
        function onChanged() { volumeOsd.show() }
    }
    Connections {
        target: Svc.Brightness
        function onChanged() { brightnessOsd.show() }
    }
}
