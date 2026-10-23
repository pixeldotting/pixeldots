import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.config
import qs.services

// Quick settings popout next to the bar: toggles, sliders and Wi-Fi / Bluetooth / audio / power details.
DrawerPanel {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btConnectedDevices: Bluetooth.devices.values.filter(d => d.connected)

    // "wifi" | "bluetooth" | "audio" | "power"
    property string tab: "wifi"

    width: 420
    height: layout.implicitHeight + 32
    hideX: -40

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: "Quick settings"
                font.pixelSize: Appearance.font.title
                font.weight: Font.Medium
            }

            StyledRect {
                visible: Power.hasBattery
                Layout.preferredHeight: 32
                Layout.preferredWidth: batteryRow.implicitWidth + 20
                radius: Appearance.rounding.full
                color: Power.low ? Colors.errorContainer : Colors.surfaceContainerHighest

                RowLayout {
                    id: batteryRow
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: Power.icon
                        size: 18
                        fill: 1
                        color: Power.low ? Colors.onErrorContainer : Colors.primary
                    }
                    StyledText {
                        text: Math.round(Power.percent) + "%"
                        font.pixelSize: Appearance.font.label
                        font.weight: Font.Medium
                        color: Power.low ? Colors.onErrorContainer : Colors.onSurface
                    }
                }
            }
        }

        // toggles
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Tile {
                Layout.fillWidth: true
                icon: Network.icon
                label: "Wi-Fi"
                sublabel: Network.summary
                checked: Network.wifiEnabled
                onClicked: Network.toggleWifi()
                onSecondaryClicked: root.tab = "wifi"
            }
            Tile {
                Layout.fillWidth: true
                icon: root.adapter?.enabled ? "bluetooth" : "bluetooth_disabled"
                label: "Bluetooth"
                sublabel: !root.adapter ? "No adapter" : !root.adapter.enabled ? "Off" : root.btConnectedDevices.length > 0 ? root.btConnectedDevices[0].name : "On"
                checked: root.adapter?.enabled ?? false
                onClicked: {
                    if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled;
                }
                onSecondaryClicked: root.tab = "bluetooth"
            }
            Tile {
                Layout.fillWidth: true
                icon: Notifs.dnd ? "notifications_off" : "notifications"
                label: "Do not disturb"
                sublabel: Notifs.dnd ? "On" : "Off"
                checked: Notifs.dnd
                onClicked: Notifs.toggleDnd()
            }
            Tile {
                Layout.fillWidth: true
                icon: Audio.micIcon
                label: "Microphone"
                sublabel: Audio.micMuted ? "Muted" : "Live"
                checked: !Audio.micMuted
                onClicked: Audio.toggleMicMute()
            }
            Tile {
                Layout.fillWidth: true
                icon: Wallpapers.mode === "dark" ? "dark_mode" : "light_mode"
                label: "Dark mode"
                sublabel: Wallpapers.mode === "dark" ? "On" : "Off"
                checked: Wallpapers.mode === "dark"
                onClicked: Wallpapers.toggleMode()
            }
            Tile {
                Layout.fillWidth: true
                icon: "sports_esports"
                label: "Game mode"
                sublabel: Hypr.gameMode ? "No effects" : "Off"
                checked: Hypr.gameMode
                onClicked: Hypr.toggleGameMode()
            }
        }

        // sliders
        M3Slider {
            Layout.fillWidth: true
            icon: Audio.icon
            value: Audio.volume
            onMoved: v => Audio.setVolume(v)
        }
        M3Slider {
            Layout.fillWidth: true
            visible: Brightness.available
            icon: "brightness_6"
            value: Brightness.value
            onMoved: v => Brightness.set(v)
        }

        // detail tabs
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Chip {
                text: "Wi-Fi"
                icon: "wifi"
                selected: root.tab === "wifi"
                onClicked: root.tab = "wifi"
            }
            Chip {
                text: "Bluetooth"
                icon: "bluetooth"
                selected: root.tab === "bluetooth"
                onClicked: root.tab = "bluetooth"
            }
            Chip {
                text: "Audio"
                icon: "speaker"
                selected: root.tab === "audio"
                onClicked: root.tab = "audio"
            }
            Chip {
                text: "Power"
                icon: "bolt"
                selected: root.tab === "power"
                onClicked: root.tab = "power"
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 230
            radius: Appearance.rounding.lg
            color: Colors.surfaceContainerHigh
            clip: true

            StackLayout {
                anchors.fill: parent
                anchors.margins: 8
                currentIndex: ["wifi", "bluetooth", "audio", "power"].indexOf(root.tab)

                WifiPanel {}
                BluetoothPanel {}
                AudioPanel {}
                PowerPanel {}
            }
        }
    }
}
