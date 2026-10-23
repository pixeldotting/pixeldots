import QtQuick
import qs.config

// Surface that fades / scales / slides in. `visible` stays true while the exit animation runs,
// which is what Drawers.qml uses to size the input mask.
StyledRect {
    id: root

    property bool shown: false
    // slide offset while hidden (px)
    property real hideX: 0
    property real hideY: 0
    property real hiddenScale: 0.94

    color: Colors.surfaceContainer
    radius: Appearance.rounding.xl
    border.width: 1
    border.color: Qt.alpha(Colors.outlineVariant, 0.5)

    opacity: shown ? 1 : 0
    scale: shown ? 1 : hiddenScale
    visible: opacity > 0.01

    Behavior on opacity {
        Anim {
            duration: root.shown ? Appearance.anim.normal : Appearance.anim.fast
        }
    }
    Behavior on scale {
        Anim {
            duration: Appearance.anim.slow
            easing.bezierCurve: Appearance.anim.emphasizedDecel
        }
    }

    transform: Translate {
        x: root.shown ? 0 : root.hideX
        y: root.shown ? 0 : root.hideY

        Behavior on x {
            Anim {
                duration: Appearance.anim.slow
                easing.bezierCurve: Appearance.anim.emphasizedDecel
            }
        }
        Behavior on y {
            Anim {
                duration: Appearance.anim.slow
                easing.bezierCurve: Appearance.anim.emphasizedDecel
            }
        }
    }

    // swallow stray clicks so they don't fall through to windows below the panel
    MouseArea {
        anchors.fill: parent
        z: -1
    }
}
