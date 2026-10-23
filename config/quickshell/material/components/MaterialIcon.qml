import QtQuick
import qs.config

// Material Symbols Rounded glyph. `fill` morphs between outlined (0) and filled (1).
StyledText {
    property real fill: 0
    property int size: 24

    font.family: Appearance.font.icon
    font.pixelSize: size
    font.variableAxes: ({
            "FILL": fill.toFixed(1),
            "opsz": Math.max(20, Math.min(48, size))
        })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideNone

    Behavior on fill {
        Anim {}
    }
}
