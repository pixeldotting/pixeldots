import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

StyledRect {
    id: root

    implicitHeight: 250
    radius: Appearance.rounding.lg
    color: Colors.surfaceContainerHigh

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            RoundImage {
                id: face
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 22
                source: "file://" + Config.facePath
                visible: status === Image.Ready
            }
            MaterialIcon {
                visible: !face.visible
                text: "account_circle"
                size: 44
                color: Colors.primary
                fill: 1
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: Time.greeting
                    color: Colors.onSurfaceVariant
                    font.pixelSize: Appearance.font.label
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Quickshell.env("USER")
                    font.pixelSize: Appearance.font.title
                    font.weight: Font.Medium
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        StyledText {
            text: Time.time
            color: Colors.primary
            font.pixelSize: Appearance.font.display
            font.weight: Font.DemiBold
        }
        StyledText {
            text: Time.day + ", " + Time.dateLong
            color: Colors.onSurfaceVariant
        }

        Item {
            Layout.preferredHeight: 6
        }

        // weather chip
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: Appearance.rounding.md
            color: Colors.tertiaryContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                MaterialIcon {
                    text: Weather.loaded ? Weather.icon : "cloud_off"
                    size: 26
                    fill: 1
                    color: Colors.onTertiaryContainer
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Weather.loaded ? Math.round(Weather.temp) + "°C  ·  " + Weather.description : "Weather unavailable"
                    color: Colors.onTertiaryContainer
                    font.weight: Font.Medium
                }
            }
        }
    }
}
