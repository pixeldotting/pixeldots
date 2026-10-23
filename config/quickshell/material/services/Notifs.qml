pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

// Notification daemon (org.freedesktop.Notifications) + history.
Singleton {
    id: root

    property bool dnd: false
    // newest first
    property var list: []
    readonly property var popups: list.filter(n => n.popup)
    readonly property int count: list.length

    function init(): void {
    }

    function clear(): void {
        for (const n of [...list])
            n.close();
    }

    function toggleDnd(): void {
        dnd = !dnd;
        if (dnd)
            for (const n of list)
                n.popup = false;
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;
            root.list = [notifComp.createObject(root, {
                    notification: notif,
                    popup: !root.dnd || notif.urgency === NotificationUrgency.Critical
                }), ...root.list];
        }
    }

    Component {
        id: notifComp

        Notif {}
    }

    component Notif: QtObject {
        id: n

        required property Notification notification
        property bool popup: true
        readonly property date time: new Date()
        readonly property bool critical: notification.urgency === NotificationUrgency.Critical

        function close(): void {
            notification.dismiss();
        }

        // expireTimeout is in seconds (0 = server default)
        property Timer hideTimer: Timer {
            interval: n.notification.expireTimeout > 0 ? n.notification.expireTimeout * 1000 : Config.notifTimeout
            running: n.popup && !n.critical
            onTriggered: n.popup = false
        }

        property Connections closer: Connections {
            target: n.notification

            function onClosed(): void {
                root.list = root.list.filter(x => x !== n);
                n.destroy();
            }
        }
    }
}
