import QtQuick
import qs.components
import qs.config
import qs.services

// Bell with unread count; click opens the notification sidebar, right click toggles Do Not Disturb.
Item {
    id: root

    implicitWidth: 40
    implicitHeight: 40

    StyledRect {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: Visibilities.active === "sidebar" ? Colors.primary : "transparent"

        MaterialIcon {
            anchors.centerIn: parent
            size: 22
            text: Notifs.dnd ? "notifications_off" : Notifs.count > 0 ? "notifications_unread" : "notifications"
            fill: Notifs.count > 0 ? 1 : 0
            color: Visibilities.active === "sidebar" ? Colors.onPrimary : Notifs.count > 0 ? Colors.primary : Colors.onSurfaceVariant
        }

        StateLayer {
            radius: parent.radius
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: event => event.button === Qt.RightButton ? Notifs.toggleDnd() : Visibilities.toggle("sidebar")
        }
    }
}
