import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Wallpaper layer with a cross-fade whenever the wallpaper changes.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData

        screen: modelData
        color: Colors.surface
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "material-background"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        readonly property string path: Wallpapers.current !== "" ? "file://" + Wallpapers.current : ""

        onPathChanged: {
            previous.source = current.source;
            current.opacity = 0;
            current.source = path;
        }

        Image {
            id: previous
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(win.width, win.height)
        }

        Image {
            id: current
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: 0
            sourceSize: Qt.size(win.width, win.height)

            onStatusChanged: {
                if (status === Image.Ready)
                    fade.restart();
            }

            Component.onCompleted: source = win.path
        }

        NumberAnimation {
            id: fade
            target: current
            property: "opacity"
            from: 0
            to: 1
            duration: Appearance.anim.expressive
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.standard
            onFinished: previous.source = current.source
        }
    }
}
