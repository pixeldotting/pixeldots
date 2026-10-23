import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Output device picker + microphone level.
ColumnLayout {
    spacing: 4

    StyledText {
        Layout.leftMargin: 8
        text: "Output"
        color: Colors.onSurfaceVariant
        font.pixelSize: Appearance.font.label
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: Audio.sinks

        delegate: StyledRect {
            id: row

            required property var modelData

            readonly property bool current: Audio.sink === modelData

            width: ListView.view.width
            height: 46
            radius: Appearance.rounding.md
            color: current ? Colors.secondaryContainer : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                MaterialIcon {
                    text: row.current ? "speaker" : "speaker_group"
                    size: 22
                    fill: row.current ? 1 : 0
                    color: row.current ? Colors.onSecondaryContainer : Colors.onSurface
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Audio.nodeName(row.modelData)
                    color: row.current ? Colors.onSecondaryContainer : Colors.onSurface
                }
                MaterialIcon {
                    visible: row.current
                    text: "check"
                    size: 18
                    color: Colors.onSecondaryContainer
                }
            }

            StateLayer {
                radius: row.radius
                onClicked: Audio.setOutput(row.modelData)
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "No output devices"
            color: Colors.onSurfaceVariant
        }
    }

    M3Slider {
        Layout.fillWidth: true
        implicitHeight: 32
        icon: Audio.micIcon
        value: Audio.micVolume
        onMoved: v => Audio.setMicVolume(v)
    }
}
