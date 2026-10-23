import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Vertical clock; click opens the dashboard.
Item {
    implicitWidth: 40
    implicitHeight: col.implicitHeight + 8

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: -2

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.hours
            color: Colors.primary
            font.pixelSize: Appearance.font.bodyLarge
            font.weight: Font.Bold
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.minutes
            color: Colors.onSurface
            font.pixelSize: Appearance.font.bodyLarge
            font.weight: Font.Medium
        }
    }

    StateLayer {
        radius: Appearance.rounding.md
        onClicked: Visibilities.toggle("dashboard")
    }
}
