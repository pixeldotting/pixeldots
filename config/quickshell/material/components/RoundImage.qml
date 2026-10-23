import QtQuick
import Quickshell.Widgets
import qs.config

// Image clipped to rounded corners.
ClippingRectangle {
    id: root

    property string source
    property size sourceSize: Qt.size(0, 0)
    property int fillMode: Image.PreserveAspectCrop
    readonly property alias status: img.status

    color: Colors.surfaceContainerHigh
    radius: Appearance.rounding.md

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        sourceSize: root.sourceSize
        fillMode: root.fillMode
        asynchronous: true
        cache: true
        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            Anim {}
        }
    }
}
