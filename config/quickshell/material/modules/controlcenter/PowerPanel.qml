import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Power profile + battery summary.
ColumnLayout {
    id: root

    spacing: 10

    readonly property var profiles: [
        {
            id: "power-saver",
            name: "Power saver",
            icon: "eco"
        },
        {
            id: "balanced",
            name: "Balanced",
            icon: "balance"
        },
        {
            id: "performance",
            name: "Performance",
            icon: "speed"
        }
    ]

    StyledText {
        Layout.leftMargin: 8
        text: "Power profile"
        color: Colors.onSurfaceVariant
        font.pixelSize: Appearance.font.label
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        visible: Power.profilesAvailable

        Repeater {
            model: root.profiles

            Tile {
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 84
                radius: checked ? Appearance.rounding.lg : Appearance.rounding.xl
                icon: modelData.icon
                label: modelData.name
                checked: Power.profile === modelData.id
                onClicked: Power.setProfile(modelData.id)
            }
        }
    }

    StyledText {
        Layout.leftMargin: 8
        visible: !Power.profilesAvailable
        text: "power-profiles-daemon is not running"
        color: Colors.onSurfaceVariant
    }

    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        Layout.leftMargin: 8
        visible: Power.hasBattery
        spacing: 10

        MaterialIcon {
            text: Power.icon
            size: 28
            fill: 1
            color: Power.low ? Colors.error : Colors.primary
        }
        StyledText {
            text: Math.round(Power.percent) + "%  ·  " + (Power.charging ? "Charging" : "On battery")
            font.weight: Font.Medium
        }
    }
}
