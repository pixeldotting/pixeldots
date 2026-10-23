import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Top-centre dashboard: clock + weather, calendar, media player and system gauges.
DrawerPanel {
    id: root

    width: 860
    height: layout.implicitHeight + 32
    hideY: -40

    onShownChanged: {
        if (shown)
            Weather.reload();
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ClockCard {
                Layout.preferredWidth: 290
                Layout.fillHeight: true
            }
            CalendarCard {
                Layout.preferredWidth: 270
                Layout.fillHeight: true
                active: root.shown
            }
            MediaCard {
                Layout.preferredWidth: 250
                Layout.fillHeight: true
            }
        }

        ResourceCard {
            Layout.fillWidth: true
        }
    }
}
