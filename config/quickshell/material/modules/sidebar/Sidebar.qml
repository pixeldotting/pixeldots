import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.modules.notifications
import qs.services

// Right-hand notification centre.
DrawerPanel {
    id: root

    width: 420
    hideX: 60

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: "Notifications"
                font.pixelSize: Appearance.font.title
                font.weight: Font.Medium
            }

            IconButton {
                icon: Notifs.dnd ? "notifications_off" : "notifications_active"
                toggle: true
                checked: Notifs.dnd
                onClicked: Notifs.toggleDnd()
            }
            IconButton {
                icon: "clear_all"
                enabled: Notifs.count > 0
                opacity: enabled ? 1 : 0.4
                onClicked: Notifs.clear()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                spacing: 8
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Notifs.list

                delegate: NotifCard {
                    required property var modelData

                    notif: modelData
                    width: ListView.view.width
                }

                add: Transition {
                    Anim {
                        property: "opacity"
                        from: 0
                        to: 1
                    }
                }
                displaced: Transition {
                    Anim {
                        property: "y"
                        duration: Appearance.anim.slow
                        easing.bezierCurve: Appearance.anim.emphasizedDecel
                    }
                }
            }

            // empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: Notifs.count === 0
                spacing: 8

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: Notifs.dnd ? "notifications_off" : "notifications_paused"
                    size: 72
                    color: Colors.outlineVariant
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Notifs.dnd ? "Do not disturb is on" : "All caught up"
                    color: Colors.onSurfaceVariant
                }
            }
        }
    }
}
