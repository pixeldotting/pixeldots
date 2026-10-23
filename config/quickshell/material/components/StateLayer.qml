import QtQuick
import qs.config

// Hover / press overlay (M3 "state layer"). Put it as the last child of the surface it should cover.
MouseArea {
    id: root

    property color color: Colors.onSurface
    property real radius: 0
    property bool disabled: false

    anchors.fill: parent
    hoverEnabled: true
    enabled: !disabled
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(root.color, root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0)

        Behavior on color {
            CAnim {
                duration: Appearance.anim.fast
            }
        }
    }
}
