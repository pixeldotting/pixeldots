import QtQuick
import QtQuick.Layouts
import qs.config

// M3 filter / assist chip.
StyledRect {
    id: root

    property string text
    property string icon: ""
    property bool selected: false

    signal clicked

    implicitHeight: 34
    implicitWidth: row.implicitWidth + 24
    radius: Appearance.rounding.sm
    color: selected ? Colors.secondaryContainer : "transparent"
    border.width: selected ? 0 : 1
    border.color: Colors.outlineVariant

    readonly property color fg: selected ? Colors.onSecondaryContainer : Colors.onSurfaceVariant

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        MaterialIcon {
            visible: root.icon !== ""
            text: root.icon
            size: 18
            color: root.fg
            fill: root.selected ? 1 : 0
        }
        StyledText {
            text: root.text
            color: root.fg
            font.pixelSize: Appearance.font.label
            font.weight: Font.Medium
        }
    }

    StateLayer {
        color: root.fg
        radius: root.radius
        onClicked: root.clicked()
    }
}
