import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Month grid, Monday first.
StyledRect {
    id: root

    property bool active: false
    property int monthOffset: 0

    readonly property date first: new Date(Time.yearNum, Time.monthNum + monthOffset, 1)
    readonly property int startOffset: (first.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()

    implicitHeight: 250
    radius: Appearance.rounding.lg
    color: Colors.surfaceContainerHigh

    onActiveChanged: {
        if (!active)
            monthOffset = 0;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            IconButton {
                icon: "chevron_left"
                variant: "standard"
                size: 32
                iconSize: 20
                onClicked: root.monthOffset--
            }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(root.first, "MMMM yyyy")
                font.weight: Font.Medium
                color: root.monthOffset === 0 ? Colors.primary : Colors.onSurface

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.monthOffset = 0
                }
            }
            IconButton {
                icon: "chevron_right"
                variant: "standard"
                size: 32
                iconSize: 20
                onClicked: root.monthOffset++
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]

                StyledText {
                    required property string modelData

                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Colors.onSurfaceVariant
                    font.pixelSize: Appearance.font.labelSmall
                    font.weight: Font.Medium
                }
            }

            Repeater {
                model: 42

                Item {
                    id: cell

                    required property int index

                    readonly property int day: index - root.startOffset + 1
                    readonly property bool valid: day >= 1 && day <= root.daysInMonth
                    readonly property bool today: valid && root.monthOffset === 0 && day === Time.dayNum

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    StyledRect {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        radius: Appearance.rounding.full
                        color: cell.today ? Colors.primary : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            visible: cell.valid
                            text: cell.day
                            font.pixelSize: Appearance.font.label
                            font.weight: cell.today ? Font.Bold : Font.Normal
                            color: cell.today ? Colors.onPrimary : Colors.onSurface
                        }
                    }
                }
            }
        }
    }
}
