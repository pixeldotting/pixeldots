import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.config
import qs.services

// Network / Bluetooth / volume / battery; click opens the control centre.
StyledRect {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property int btConnected: Bluetooth.devices.values.filter(d => d.connected).length
    readonly property string btIcon: !adapter?.enabled ? "bluetooth_disabled" : btConnected > 0 ? "bluetooth_connected" : "bluetooth"

    implicitWidth: 40
    implicitHeight: col.implicitHeight + 16
    radius: Appearance.rounding.full
    color: Visibilities.active === "controlcenter" ? Colors.secondaryContainer : Colors.surfaceContainerHigh

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: Appearance.spacing.md

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            size: 20
            text: Network.icon
            color: Network.connected ? Colors.onSurface : Colors.error
        }
        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            size: 20
            text: root.btIcon
            color: root.adapter?.enabled ? Colors.onSurface : Colors.outline
        }
        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            size: 20
            text: Audio.icon
            color: Audio.muted ? Colors.outline : Colors.onSurface
        }
        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            visible: Power.hasBattery
            size: 20
            text: Power.icon
            fill: 1
            color: Power.low ? Colors.error : Power.charging ? Colors.primary : Colors.onSurface
        }
    }

    StateLayer {
        radius: root.radius
        onClicked: Visibilities.toggle("controlcenter")
    }
}
