import QtQuick
import QtQuick.Shapes
import qs.config

// Circular gauge. Children are centred inside the ring.
Item {
    id: root

    property real value: 0   // 0..1
    property real lineWidth: 8
    property color color: Colors.primary
    property color trackColor: Colors.surfaceContainerHighest

    default property alias content: inner.data

    implicitWidth: 88
    implicitHeight: 88

    Behavior on value {
        Anim {
            duration: Appearance.anim.slow
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2
                radiusY: (root.height - root.lineWidth) / 2
                startAngle: -90
                sweepAngle: 359.9
            }
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2
                radiusY: (root.height - root.lineWidth) / 2
                startAngle: -90
                sweepAngle: 359.9 * Math.max(0.001, Math.min(1, root.value))
            }
        }
    }

    Item {
        id: inner
        anchors.centerIn: parent
        width: parent.width - root.lineWidth * 2
        height: parent.height - root.lineWidth * 2
    }
}
