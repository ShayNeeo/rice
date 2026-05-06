pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        WlrLayershell.namespace: "test-layer"
        width: 100
        height: 100
    }
}
