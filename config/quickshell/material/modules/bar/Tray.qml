import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config

ColumnLayout {
    spacing: Appearance.spacing.sm

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: delegate

            required property SystemTrayItem modelData

            implicitWidth: 28
            implicitHeight: 28
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            onClicked: event => {
                if (event.button === Qt.LeftButton && !modelData.onlyMenu)
                    modelData.activate();
                else if (event.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else if (modelData.hasMenu)
                    menu.open();
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 20
                source: delegate.modelData.icon
            }

            QsMenuAnchor {
                id: menu
                menu: delegate.modelData.menu
                anchor.item: delegate
                anchor.edges: Edges.Right
                anchor.gravity: Edges.Right
            }
        }
    }
}
