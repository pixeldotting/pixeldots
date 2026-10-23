pragma Singleton

import QtQuick
import Quickshell

// Design tokens: shape, spacing, type and motion (Material 3 / expressive).
Singleton {
    id: root

    readonly property QtObject rounding: QtObject {
        readonly property int xs: 8
        readonly property int sm: 12
        readonly property int md: 16
        readonly property int lg: 24
        readonly property int xl: 32
        readonly property int full: 1000
    }

    readonly property QtObject spacing: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 24
    }

    readonly property QtObject font: QtObject {
        readonly property string sans: "Rubik"
        readonly property string mono: "CaskaydiaCove Nerd Font"
        readonly property string icon: "Material Symbols Rounded"

        readonly property int labelSmall: 11
        readonly property int label: 12
        readonly property int body: 14
        readonly property int bodyLarge: 16
        readonly property int title: 20
        readonly property int headline: 28
        readonly property int display: 56
    }

    // Material motion tokens (cubic-bezier control points, QML BezierSpline format).
    readonly property QtObject anim: QtObject {
        readonly property int fast: 150
        readonly property int normal: 250
        readonly property int slow: 400
        readonly property int expressive: 550

        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        // overshoots slightly: used for shape / position changes
        readonly property list<real> spatial: [0.38, 1.21, 0.22, 1, 1, 1]
    }

    readonly property int barWidth: 56
    readonly property int barMargin: 8
    readonly property int barTotal: barWidth + barMargin * 2
    readonly property int panelMargin: 12
}
