import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

StyledRect {
    id: root

    implicitHeight: 128
    radius: Appearance.rounding.lg
    color: Colors.surfaceContainerHigh

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Gauge {
            Layout.fillWidth: true
            icon: "memory"
            label: "CPU"
            value: SystemUsage.cpu
            detail: Math.round(SystemUsage.cpu * 100) + "%"
        }
        Gauge {
            Layout.fillWidth: true
            icon: "developer_board"
            label: "Memory"
            color: Colors.secondary
            value: SystemUsage.mem
            detail: SystemUsage.memUsed.toFixed(1) + " / " + SystemUsage.memTotal.toFixed(0) + " GiB"
        }
        Gauge {
            Layout.fillWidth: true
            icon: "hard_drive"
            label: "Disk"
            color: Colors.tertiary
            value: SystemUsage.disk
            detail: SystemUsage.diskUsed.toFixed(0) + " / " + SystemUsage.diskTotal.toFixed(0) + " GiB"
        }
        Gauge {
            Layout.fillWidth: true
            visible: Power.hasBattery
            icon: Power.icon
            label: "Battery"
            color: Power.low ? Colors.error : Colors.primary
            value: Power.percent / 100
            detail: Math.round(Power.percent) + "%" + (Power.charging ? " · charging" : "")
        }
    }
}
