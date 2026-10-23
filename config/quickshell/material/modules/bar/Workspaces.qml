import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.config
import qs.services

// Workspace pill with a sliding active indicator. Workspaces are paged in groups of `Config.workspaces`.
StyledRect {
    id: root

    required property var screen

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int shown: Config.workspaces
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int base: Math.floor((activeId - 1) / shown) * shown
    readonly property int cell: 32
    readonly property int pad: 4

    implicitWidth: cell + pad * 2
    implicitHeight: shown * cell + pad * 2
    radius: Appearance.rounding.full
    color: Colors.surfaceContainerHigh

    StyledRect {
        x: root.pad
        y: root.pad + (root.activeId - root.base - 1) * root.cell
        width: root.cell
        height: root.cell
        radius: Appearance.rounding.full
        color: Colors.primary

        Behavior on y {
            Anim {
                duration: Appearance.anim.slow
                easing.bezierCurve: Appearance.anim.spatial
            }
        }
    }

    Repeater {
        model: root.shown

        Item {
            id: ws

            required property int index

            readonly property int wsId: root.base + index + 1
            readonly property bool active: wsId === root.activeId
            readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId && (w.lastIpcObject?.windows ?? 0) > 0)

            x: root.pad
            y: root.pad + index * root.cell
            width: root.cell
            height: root.cell

            StyledText {
                anchors.centerIn: parent
                visible: ws.active || ws.occupied
                text: ws.wsId
                font.weight: ws.active ? Font.Bold : Font.Medium
                color: ws.active ? Colors.onPrimary : Colors.onSurface
            }

            Rectangle {
                anchors.centerIn: parent
                visible: !(ws.active || ws.occupied)
                width: 6
                height: 6
                radius: 3
                color: Colors.outline
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.focusWorkspace(ws.wsId)
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => Hypr.focusWorkspace(event.angleDelta.y > 0 ? "e-1" : "e+1")
    }
}
