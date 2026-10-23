import QtQuick
import qs.config

// M3 icon button. Toggle buttons morph from a circle to a rounded square when checked.
StyledRect {
    id: root

    property string icon
    property bool checked: false
    property bool toggle: false
    // "standard" | "tonal" | "filled"
    property string variant: "tonal"
    property int size: 40
    property int iconSize: 22

    signal clicked

    readonly property bool active: toggle ? checked : variant === "filled"
    readonly property color fg: active ? Colors.onPrimary : variant === "standard" ? Colors.onSurfaceVariant : Colors.onSecondaryContainer

    implicitWidth: size
    implicitHeight: size
    radius: toggle && checked ? Appearance.rounding.md : Appearance.rounding.full
    color: active ? Colors.primary : variant === "standard" ? "transparent" : Colors.secondaryContainer

    Behavior on radius {
        Anim {
            duration: Appearance.anim.slow
            easing.bezierCurve: Appearance.anim.spatial
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.icon
        size: root.iconSize
        color: root.fg
        fill: root.checked ? 1 : 0
    }

    StateLayer {
        color: root.fg
        radius: root.radius
        onClicked: root.clicked()
    }
}
