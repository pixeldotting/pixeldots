import QtQuick
import qs.config

Rectangle {
    color: Colors.surfaceContainer
    radius: Appearance.rounding.md

    Behavior on color {
        CAnim {}
    }
}
