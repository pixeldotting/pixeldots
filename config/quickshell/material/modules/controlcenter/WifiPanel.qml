import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

ColumnLayout {
    id: root

    // ssid whose password prompt is open
    property string asking: ""

    spacing: 4

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        visible: Network.error !== ""
        text: Network.error
        color: Colors.error
        font.pixelSize: Appearance.font.label
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: Network.wifiEnabled ? Network.networks : []

        delegate: StyledRect {
            id: row

            required property var modelData

            readonly property bool asking: root.asking === modelData.ssid

            width: ListView.view.width
            height: asking ? 100 : 48
            radius: Appearance.rounding.md
            color: modelData.active ? Colors.secondaryContainer : "transparent"
            clip: true

            Behavior on height {
                Anim {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    spacing: 12

                    MaterialIcon {
                        text: row.modelData.signal > 75 ? "signal_wifi_4_bar" : row.modelData.signal > 50 ? "network_wifi_3_bar" : row.modelData.signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                        size: 22
                        color: row.modelData.active ? Colors.onSecondaryContainer : Colors.onSurface
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.ssid
                        color: row.modelData.active ? Colors.onSecondaryContainer : Colors.onSurface
                        font.weight: row.modelData.active ? Font.Medium : Font.Normal
                    }
                    MaterialIcon {
                        visible: row.modelData.secure
                        text: "lock"
                        size: 16
                        color: Colors.onSurfaceVariant
                    }
                    MaterialIcon {
                        visible: row.modelData.active
                        text: "check"
                        size: 18
                        color: Colors.onSecondaryContainer
                    }
                }

                // password prompt
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    visible: row.asking
                    radius: Appearance.rounding.full
                    color: Colors.surfaceContainerHighest

                    TextInput {
                        id: pass
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Colors.onSurface
                        font.family: Appearance.font.sans
                        font.pixelSize: Appearance.font.body
                        onAccepted: {
                            Network.connect(row.modelData.ssid, text);
                            text = "";
                            root.asking = "";
                        }

                        StyledText {
                            anchors.fill: parent
                            visible: pass.text === ""
                            text: "Password"
                            color: Colors.onSurfaceVariant
                        }

                        Connections {
                            target: row
                            function onAskingChanged() {
                                if (row.asking)
                                    pass.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            StateLayer {
                anchors.bottomMargin: row.asking ? 52 : 0
                radius: row.radius
                onClicked: {
                    if (row.modelData.active) {
                        Network.disconnect();
                    } else if (row.modelData.secure && !row.modelData.known) {
                        root.asking = row.asking ? "" : row.modelData.ssid;
                    } else {
                        Network.connect(row.modelData.ssid, "");
                    }
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: list.count === 0
            text: Network.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
            color: Colors.onSurfaceVariant
        }
    }
}
