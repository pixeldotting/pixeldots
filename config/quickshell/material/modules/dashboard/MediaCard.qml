import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

StyledRect {
    id: root

    implicitHeight: 250
    radius: Appearance.rounding.lg
    color: Colors.surfaceContainerHigh

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // cover art
        RoundImage {
            id: art
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 112
            Layout.preferredHeight: 112
            radius: Appearance.rounding.lg
            source: Media.art
            sourceSize: Qt.size(224, 224)

            MaterialIcon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: Media.hasPlayer ? "music_note" : "music_off"
                size: 44
                color: Colors.onSurfaceVariant
            }
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Media.title
            font.weight: Font.Medium
            font.pixelSize: Appearance.font.bodyLarge
        }
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Media.artist
            color: Colors.onSurfaceVariant
            font.pixelSize: Appearance.font.label
            visible: text !== ""
        }

        M3Slider {
            Layout.fillWidth: true
            implicitHeight: 14
            visible: Media.hasPlayer && Media.length > 0
            value: Media.length > 0 ? Media.position / Media.length : 0
            onMoved: v => {
                if (Media.active?.canSeek)
                    Media.active.position = v * Media.length;
            }
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            IconButton {
                icon: "skip_previous"
                variant: "standard"
                enabled: Media.active?.canGoPrevious ?? false
                onClicked: Media.active.previous()
            }
            IconButton {
                icon: Media.playing ? "pause" : "play_arrow"
                variant: "filled"
                size: 48
                iconSize: 28
                enabled: Media.hasPlayer
                onClicked: Media.active.togglePlaying()
            }
            IconButton {
                icon: "skip_next"
                variant: "standard"
                enabled: Media.active?.canGoNext ?? false
                onClicked: Media.active.next()
            }
        }
    }
}
