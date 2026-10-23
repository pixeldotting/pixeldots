import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Volume / brightness / mic popup on the right edge.
DrawerPanel {
    id: root

    property bool onScreen: true
    property bool armed: false
    property bool open: false
    // "volume" | "brightness" | "mic"
    property string kind: "volume"

    readonly property real level: kind === "brightness" ? Brightness.value : kind === "mic" ? Audio.micVolume : Audio.volume
    readonly property bool muted: kind === "volume" ? Audio.muted : kind === "mic" ? Audio.micMuted : false
    readonly property string icon: kind === "brightness" ? (level > 0.66 ? "brightness_high" : level > 0.33 ? "brightness_medium" : "brightness_low") : kind === "mic" ? Audio.micIcon : Audio.icon

    function show(k: string): void {
        if (!armed)
            return;
        kind = k;
        open = true;
        hideTimer.restart();
    }

    shown: open && onScreen
    width: 72
    height: 260
    radius: Appearance.rounding.full
    hideX: 40
    color: Colors.surfaceContainerHigh

    // ignore the volume jump that happens while PipeWire starts up
    Timer {
        interval: 3500
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: root.open = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            root.show("volume");
        }
        function onMutedChanged() {
            root.show("volume");
        }
        function onMicMutedChanged() {
            root.show("mic");
        }
    }

    Connections {
        target: Brightness
        function onChanged() {
            root.show("brightness");
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 18
        anchors.bottomMargin: 18
        spacing: 12

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.muted ? "mute" : Math.round(root.level * 100)
            font.pixelSize: Appearance.font.label
            font.weight: Font.Medium
            color: Colors.onSurfaceVariant
        }

        // vertical level bar
        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.preferredWidth: 28
            radius: Appearance.rounding.full
            color: Colors.secondaryContainer
            clip: true

            StyledRect {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.max(width, parent.height * (root.muted ? 0 : Math.min(1, root.level)))
                radius: Appearance.rounding.full
                color: root.muted ? Colors.outline : Colors.primary

                Behavior on height {
                    Anim {
                        duration: Appearance.anim.fast
                    }
                }
            }
        }

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            size: 26
            fill: 1
            color: Colors.primary
        }
    }
}
