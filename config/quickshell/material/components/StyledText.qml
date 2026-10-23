import QtQuick
import qs.config

Text {
    color: Colors.onSurface
    font.family: Appearance.font.sans
    font.pixelSize: Appearance.font.body
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        CAnim {}
    }
}
