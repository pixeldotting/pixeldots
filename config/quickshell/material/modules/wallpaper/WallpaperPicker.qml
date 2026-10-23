import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services

// Wallpaper grid + Material You scheme controls. Picking an image regenerates every theme file.
DrawerPanel {
    id: root

    width: 900
    height: col.implicitHeight + 32
    hideY: 40

    onShownChanged: {
        if (shown)
            Wallpapers.rescan();
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: "Wallpaper"
                font.pixelSize: Appearance.font.title
                font.weight: Font.Medium
            }

            Chip {
                text: "Dark"
                icon: "dark_mode"
                selected: Wallpapers.mode === "dark"
                onClicked: Wallpapers.setMode("dark")
            }
            Chip {
                text: "Light"
                icon: "light_mode"
                selected: Wallpapers.mode === "light"
                onClicked: Wallpapers.setMode("light")
            }
            IconButton {
                icon: "casino"
                onClicked: Wallpapers.random()
            }
        }

        // scheme variants
        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            contentWidth: variantRow.implicitWidth
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: variantRow
                spacing: 8

                Repeater {
                    model: Wallpapers.variants

                    Chip {
                        required property var modelData

                        text: modelData.name
                        selected: Wallpapers.variant === modelData.id
                        onClicked: Wallpapers.setVariant(modelData.id)
                    }
                }
            }
        }

        // thumbnails
        ListView {
            id: grid
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            orientation: ListView.Horizontal
            spacing: 12
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Wallpapers.list

            delegate: Item {
                id: thumb

                required property string modelData

                readonly property bool current: modelData === Wallpapers.current

                width: 240
                height: ListView.view.height

                StyledRect {
                    anchors.fill: parent
                    radius: Appearance.rounding.lg
                    color: thumb.current ? Colors.primary : "transparent"

                    RoundImage {
                        anchors.fill: parent
                        anchors.margins: thumb.current ? 4 : 0
                        radius: thumb.current ? Appearance.rounding.md : Appearance.rounding.lg
                        source: "file://" + thumb.modelData
                        sourceSize: Qt.size(480, 300)

                        Behavior on anchors.margins {
                            Anim {}
                        }
                    }

                    StateLayer {
                        radius: parent.radius
                        color: Colors.onSurface
                        onClicked: Wallpapers.setWallpaper(thumb.modelData)
                    }
                }

                MaterialIcon {
                    visible: thumb.current
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    text: "check_circle"
                    size: 24
                    fill: 1
                    color: Colors.onPrimary
                }
            }

            // empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: grid.count === 0
                spacing: 4

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "image_not_supported"
                    size: 40
                    color: Colors.outline
                }
                StyledText {
                    text: "No wallpapers in " + Config.wallpaperDir
                    color: Colors.onSurfaceVariant
                }
            }
        }
    }
}
