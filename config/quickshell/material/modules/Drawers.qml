import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.modules.controlcenter
import qs.modules.dashboard
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.osd
import qs.modules.session
import qs.modules.sidebar
import qs.modules.wallpaper

// One transparent full-screen layer per monitor that hosts every popup panel.
// Input is masked to the visible panels, so everything else stays click-through.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData

        // panels only open on the monitor that has focus
        readonly property bool focused: Hypr.isFocused(modelData)
        readonly property string active: focused ? Visibilities.active : ""

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "material-drawers"
        WlrLayershell.layer: Visibilities.any ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: focused && Visibilities.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            PanelRegion {
                panel: dashboard
            }
            PanelRegion {
                panel: launcher
            }
            PanelRegion {
                panel: wallpaper
            }
            PanelRegion {
                panel: sidebar
            }
            PanelRegion {
                panel: controlCenter
            }
            PanelRegion {
                panel: sessionMenu
            }
            PanelRegion {
                panel: osd
            }
            PanelRegion {
                panel: popups
            }
            // dimmed backdrop behind the session menu swallows clicks (and closes it)
            Region {
                width: scrim.visible ? win.width : 0
                height: scrim.visible ? win.height : 0
            }
        }

        // click outside any panel -> close
        HyprlandFocusGrab {
            windows: [win]
            active: win.focused && Visibilities.any
            onCleared: Visibilities.close()
        }

        Item {
            id: root
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Visibilities.close()

            Rectangle {
                id: scrim
                anchors.fill: parent
                color: Qt.alpha(Colors.scrim, 0.5)
                opacity: win.active === "session" ? 1 : 0
                visible: opacity > 0.01

                Behavior on opacity {
                    Anim {}
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Visibilities.close()
                }
            }

            Dashboard {
                id: dashboard
                shown: win.active === "dashboard"
                anchors.top: parent.top
                anchors.topMargin: Appearance.panelMargin
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Launcher {
                id: launcher
                shown: win.active === "launcher"
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.panelMargin
                anchors.horizontalCenter: parent.horizontalCenter
            }

            WallpaperPicker {
                id: wallpaper
                shown: win.active === "wallpaper"
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.panelMargin
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Sidebar {
                id: sidebar
                shown: win.active === "sidebar"
                anchors.right: parent.right
                anchors.rightMargin: Appearance.panelMargin
                anchors.top: parent.top
                anchors.topMargin: Appearance.panelMargin
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.panelMargin
            }

            ControlCenter {
                id: controlCenter
                shown: win.active === "controlcenter"
                anchors.left: parent.left
                anchors.leftMargin: Appearance.barTotal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.panelMargin
            }

            SessionMenu {
                id: sessionMenu
                shown: win.active === "session"
                anchors.centerIn: parent
            }

            Osd {
                id: osd
                onScreen: win.focused
                anchors.right: parent.right
                anchors.rightMargin: Appearance.panelMargin
                anchors.verticalCenter: parent.verticalCenter
            }

            NotifPopups {
                id: popups
                onScreen: win.focused
                suppressed: win.active === "sidebar"
                anchors.right: parent.right
                anchors.rightMargin: Appearance.panelMargin
                anchors.top: parent.top
                anchors.topMargin: Appearance.panelMargin
            }
        }
    }
}
