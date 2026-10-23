import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services

// Centred power menu. Arrow keys / Tab to move, Enter to run, Esc to close.
DrawerPanel {
    id: root

    property int index: 0

    readonly property var entries: [
        {
            icon: "lock",
            label: "Lock",
            run: () => Lockscreen.lock()
        },
        {
            icon: "logout",
            label: "Logout",
            run: () => Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")])
        },
        {
            icon: "bedtime",
            label: "Sleep",
            run: () => Quickshell.execDetached(["systemctl", "suspend"])
        },
        {
            icon: "restart_alt",
            label: "Reboot",
            run: () => Quickshell.execDetached(["systemctl", "reboot"])
        },
        {
            icon: "power_settings_new",
            label: "Shut down",
            run: () => Quickshell.execDetached(["systemctl", "poweroff"])
        }
    ]

    function activate(i: int): void {
        Visibilities.close();
        entries[i].run();
    }

    width: row.implicitWidth + 32
    height: row.implicitHeight + 32
    radius: Appearance.rounding.xl
    color: Colors.surfaceContainerHigh

    onShownChanged: {
        if (shown) {
            index = 0;
            keys.forceActiveFocus();
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onLeftPressed: root.index = (root.index + root.entries.length - 1) % root.entries.length
        Keys.onRightPressed: root.index = (root.index + 1) % root.entries.length
        Keys.onTabPressed: root.index = (root.index + 1) % root.entries.length
        Keys.onReturnPressed: root.activate(root.index)
        Keys.onEnterPressed: root.activate(root.index)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: root.entries

            StyledRect {
                id: button

                required property var modelData
                required property int index

                readonly property bool current: root.index === index
                readonly property bool danger: modelData.label === "Shut down" || modelData.label === "Reboot"

                Layout.preferredWidth: 104
                Layout.preferredHeight: 120
                radius: current ? Appearance.rounding.lg : Appearance.rounding.xl
                color: current ? (danger ? Colors.errorContainer : Colors.primaryContainer) : Colors.surfaceContainerHighest

                Behavior on radius {
                    Anim {
                        duration: Appearance.anim.slow
                        easing.bezierCurve: Appearance.anim.spatial
                    }
                }

                readonly property color fg: current ? (danger ? Colors.onErrorContainer : Colors.onPrimaryContainer) : Colors.onSurfaceVariant

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: button.modelData.icon
                        size: 40
                        fill: button.current ? 1 : 0
                        color: button.fg
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: button.modelData.label
                        color: button.fg
                        font.weight: Font.Medium
                    }
                }

                StateLayer {
                    radius: button.radius
                    color: button.fg
                    onEntered: root.index = button.index
                    onClicked: root.activate(button.index)
                }
            }
        }
    }
}
