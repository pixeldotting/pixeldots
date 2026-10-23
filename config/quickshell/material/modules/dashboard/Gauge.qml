import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config

RowLayout {
    id: root

    property string icon
    property string label
    property string detail
    property real value: 0
    property color color: Colors.primary

    spacing: 12

    ProgressRing {
        Layout.preferredWidth: 84
        Layout.preferredHeight: 84
        value: root.value
        color: root.color
        lineWidth: 9

        MaterialIcon {
            anchors.centerIn: parent
            text: root.icon
            size: 26
            fill: 1
            color: root.color
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            text: root.label
            color: Colors.onSurfaceVariant
            font.pixelSize: Appearance.font.label
        }
        StyledText {
            Layout.fillWidth: true
            text: root.detail
            font.pixelSize: Appearance.font.body
            font.weight: Font.Medium
        }
    }
}
