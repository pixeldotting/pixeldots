import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components
import qs.config

// Icon of the focused window.
Item {
    id: root

    readonly property var toplevel: Hyprland.activeToplevel
    readonly property string appClass: toplevel?.lastIpcObject?.class ?? ""

    implicitWidth: 32
    implicitHeight: appClass !== "" ? 32 : 0
    opacity: appClass !== "" ? 1 : 0

    Behavior on implicitHeight {
        Anim {}
    }
    Behavior on opacity {
        Anim {}
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 24
        source: Quickshell.iconPath(DesktopEntries.heuristicLookup(root.appClass)?.icon ?? root.appClass.toLowerCase(), "application-x-executable")
    }
}
