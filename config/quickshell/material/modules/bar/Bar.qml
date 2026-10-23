import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// Vertical pill bar on the left edge (Caelestia-style).
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData

        screen: modelData
        color: "transparent"
        WlrLayershell.namespace: "material-bar"

        anchors {
            top: true
            bottom: true
            left: true
        }

        implicitWidth: Appearance.barTotal
        exclusiveZone: Appearance.barWidth + Appearance.barMargin

        // only the pill takes input, the transparent margin stays click-through
        mask: Region {
            item: pill
        }

        StyledRect {
            id: pill

            x: Appearance.barMargin
            y: Appearance.barMargin
            width: Appearance.barWidth
            height: parent.height - Appearance.barMargin * 2
            radius: Appearance.rounding.xl
            color: Colors.surfaceContainer

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: Appearance.spacing.md

                // logo -> launcher
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 40
                    implicitHeight: 40

                    StyledRect {
                        anchors.fill: parent
                        radius: Appearance.rounding.full
                        color: Colors.primaryContainer

                        StyledText {
                            anchors.centerIn: parent
                            text: ""
                            color: Colors.onPrimaryContainer
                            font.family: Appearance.font.mono
                            font.pixelSize: 22
                        }

                        StateLayer {
                            color: Colors.onPrimaryContainer
                            radius: parent.radius
                            onClicked: Visibilities.toggle("launcher")
                        }
                    }
                }

                Workspaces {
                    Layout.alignment: Qt.AlignHCenter
                    screen: win.modelData
                }

                ActiveWindow {
                    Layout.alignment: Qt.AlignHCenter
                }

                Item {
                    Layout.fillHeight: true
                }

                Tray {
                    Layout.alignment: Qt.AlignHCenter
                }

                NotifButton {
                    Layout.alignment: Qt.AlignHCenter
                }

                ClockWidget {
                    Layout.alignment: Qt.AlignHCenter
                }

                StatusIcons {
                    Layout.alignment: Qt.AlignHCenter
                }

                IconButton {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "power_settings_new"
                    variant: "filled"
                    onClicked: Visibilities.toggle("session")
                }
            }
        }
    }
}
