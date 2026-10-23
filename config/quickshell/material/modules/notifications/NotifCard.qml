import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// One notification. Click expands the body; the cross dismisses it.
StyledRect {
    id: root

    required property var notif

    readonly property var n: notif.notification
    property bool expanded: false

    readonly property string ago: {
        Time.minutes; // re-evaluate every minute
        const mins = Math.floor((Date.now() - notif.time.getTime()) / 60000);
        return mins < 1 ? "now" : mins < 60 ? mins + " min" : Math.floor(mins / 60) + " h";
    }

    implicitWidth: 380
    implicitHeight: col.implicitHeight + 24
    radius: Appearance.rounding.lg
    color: notif.critical ? Colors.errorContainer : Colors.surfaceContainerHigh

    Behavior on implicitHeight {
        Anim {}
    }

    StateLayer {
        radius: root.radius
        color: root.notif.critical ? Colors.onErrorContainer : Colors.onSurface
        onClicked: root.expanded = !root.expanded
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // image / app icon
        Item {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44

            RoundImage {
                id: picture
                anchors.fill: parent
                radius: Appearance.rounding.md
                visible: root.n.image !== ""
                source: root.n.image
                sourceSize: Qt.size(88, 88)
            }

            StyledRect {
                anchors.fill: parent
                visible: !picture.visible
                radius: Appearance.rounding.md
                color: root.notif.critical ? Colors.error : Colors.primaryContainer

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 28
                    visible: root.n.appIcon !== ""
                    source: root.n.appIcon.startsWith("/") ? "file://" + root.n.appIcon : Quickshell.iconPath(root.n.appIcon, "notifications")
                }
                MaterialIcon {
                    anchors.centerIn: parent
                    visible: root.n.appIcon === ""
                    text: root.notif.critical ? "priority_high" : "notifications"
                    size: 24
                    fill: 1
                    color: root.notif.critical ? Colors.onError : Colors.onPrimaryContainer
                }
            }
        }

        ColumnLayout {
            id: col
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    text: root.n.appName + "  ·  " + root.ago
                    color: root.notif.critical ? Colors.onErrorContainer : Colors.onSurfaceVariant
                    font.pixelSize: Appearance.font.labelSmall
                }

                MaterialIcon {
                    text: "close"
                    size: 18
                    color: root.notif.critical ? Colors.onErrorContainer : Colors.onSurfaceVariant

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notif.close()
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.n.summary
                font.weight: Font.Medium
                font.pixelSize: Appearance.font.bodyLarge
                color: root.notif.critical ? Colors.onErrorContainer : Colors.onSurface
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.n.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: root.expanded ? 20 : 2
                color: root.notif.critical ? Colors.onErrorContainer : Colors.onSurfaceVariant
                font.pixelSize: Appearance.font.label
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: root.n.actions.length > 0
                spacing: 8

                Repeater {
                    model: root.n.actions

                    Chip {
                        required property var modelData

                        text: modelData.text
                        selected: true
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
