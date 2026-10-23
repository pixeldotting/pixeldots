import QtQuick
import QtQuick.Layouts
import qs.config

// Quick-settings tile (Wi-Fi, Bluetooth, DND ...).
StyledRect {
    id: root

    property string icon
    property string label
    property string sublabel
    property bool checked: false

    signal clicked
    signal secondaryClicked

    implicitHeight: 64
    implicitWidth: 160
    radius: checked ? Appearance.rounding.lg : Appearance.rounding.full
    color: checked ? Colors.primary : Colors.surfaceContainerHighest

    readonly property color fg: checked ? Colors.onPrimary : Colors.onSurface

    Behavior on radius {
        Anim {
            duration: Appearance.anim.slow
            easing.bezierCurve: Appearance.anim.spatial
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: Appearance.spacing.md

        MaterialIcon {
            text: root.icon
            size: 24
            color: root.fg
            fill: root.checked ? 1 : 0
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.label
                color: root.fg
                font.weight: Font.Medium
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.sublabel !== ""
                text: root.sublabel
                color: root.fg
                opacity: 0.75
                font.pixelSize: Appearance.font.labelSmall
            }
        }
    }

    StateLayer {
        color: root.fg
        radius: root.radius
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? root.secondaryClicked() : root.clicked()
    }
}
