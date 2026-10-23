import QtQuick
import qs.components
import qs.config
import qs.services

// Toast stack (top-right). Every recent notification gets a delegate; hidden ones collapse to zero height,
// which gives smooth enter / exit animations without recreating items.
Item {
    id: root

    property bool onScreen: true
    property bool suppressed: false

    readonly property bool allowed: onScreen && !suppressed

    width: 380
    height: list.contentHeight
    visible: list.contentHeight > 0

    ListView {
        id: list
        width: parent.width
        height: contentHeight
        interactive: false
        model: Notifs.list.slice(0, 6)

        delegate: Item {
            id: slot

            required property var modelData

            readonly property bool open: modelData.popup && root.allowed
            property bool entered: false

            width: ListView.view.width
            height: open ? card.implicitHeight + 8 : 0
            opacity: open && entered ? 1 : 0
            visible: height > 0.5
            clip: true

            Component.onCompleted: entered = true

            Behavior on height {
                Anim {
                    duration: Appearance.anim.slow
                    easing.bezierCurve: Appearance.anim.emphasizedDecel
                }
            }
            Behavior on opacity {
                Anim {}
            }

            NotifCard {
                id: card
                notif: slot.modelData
                width: parent.width
                y: slot.open && slot.entered ? 0 : -16

                Behavior on y {
                    Anim {
                        duration: Appearance.anim.slow
                        easing.bezierCurve: Appearance.anim.emphasizedDecel
                    }
                }
            }
        }
    }
}
