import QtQuick
import qs.config

// M3 expressive slider: fat rounded track with a leading icon and a thin handle.
Item {
    id: root

    property real value: 0   // 0..1
    property string icon: ""
    property real wheelStep: 0.05

    signal moved(real value)

    implicitHeight: 40
    implicitWidth: 220

    readonly property real shown: mouse.pressed ? dragValue : Math.max(0, Math.min(1, value))
    property real dragValue: 0

    StyledRect {
        id: track
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: Colors.secondaryContainer
        clip: true

        StyledRect {
            id: fill
            height: parent.height
            width: Math.max(height, parent.width * root.shown)
            radius: Appearance.rounding.full
            color: Colors.primary

            Behavior on width {
                enabled: !mouse.pressed
                Anim {
                    duration: Appearance.anim.fast
                }
            }
        }

        MaterialIcon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            size: 20
            text: root.icon
            color: fill.width > 44 ? Colors.onPrimary : Colors.onSecondaryContainer
        }

        // handle
        Rectangle {
            width: 4
            height: parent.height - 12
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(8, fill.width - 12)
            color: Colors.onPrimary
            opacity: 0.9
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function update(x: real): void {
            root.dragValue = Math.max(0, Math.min(1, x / width));
            root.moved(root.dragValue);
        }

        onPressed: event => update(event.x)
        onPositionChanged: event => {
            if (pressed)
                update(event.x);
        }
        onWheel: wheel => {
            const next = Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep)));
            root.moved(next);
        }
    }
}
