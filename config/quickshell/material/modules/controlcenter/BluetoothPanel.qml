import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.config

ColumnLayout {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        visible: root.adapter !== null

        StyledText {
            Layout.fillWidth: true
            text: root.adapter?.discovering ? "Searching for devices…" : "Paired devices"
            color: Colors.onSurfaceVariant
            font.pixelSize: Appearance.font.label
        }
        IconButton {
            icon: "bluetooth_searching"
            variant: "standard"
            size: 32
            iconSize: 20
            toggle: true
            checked: root.adapter?.discovering ?? false
            enabled: root.adapter?.enabled ?? false
            onClicked: root.adapter.discovering = !root.adapter.discovering
        }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: root.adapter?.enabled ? Bluetooth.devices.values.filter(d => d.paired || d.connected || root.adapter.discovering).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)) : []

        delegate: StyledRect {
            id: row

            required property var modelData

            width: ListView.view.width
            height: 52
            radius: Appearance.rounding.md
            color: modelData.connected ? Colors.secondaryContainer : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                MaterialIcon {
                    text: row.modelData.connected ? "bluetooth_connected" : "bluetooth"
                    size: 22
                    color: row.modelData.connected ? Colors.onSecondaryContainer : Colors.onSurface
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        color: row.modelData.connected ? Colors.onSecondaryContainer : Colors.onSurface
                        font.weight: row.modelData.connected ? Font.Medium : Font.Normal
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: row.modelData.connected ? (row.modelData.batteryAvailable ? "Connected · " + Math.round(row.modelData.battery * 100) + "%" : "Connected") : row.modelData.paired ? "Paired" : "Available"
                        color: Colors.onSurfaceVariant
                        font.pixelSize: Appearance.font.labelSmall
                    }
                }
            }

            StateLayer {
                radius: row.radius
                onClicked: row.modelData.connected = !row.modelData.connected
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: list.count === 0
            text: !root.adapter ? "No Bluetooth adapter" : !root.adapter.enabled ? "Bluetooth is off" : "No paired devices"
            color: Colors.onSurfaceVariant
        }
    }
}
