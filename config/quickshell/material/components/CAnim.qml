import QtQuick
import qs.config

ColorAnimation {
    duration: Appearance.anim.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.standard
}
