import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services

// One lock screen per monitor: blurred wallpaper, big clock and a password pill.
Item {
    id: root

    required property var context

    focus: true

    // blurred wallpaper
    Image {
        id: wall
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        source: Wallpapers.current !== "" ? "file://" + Wallpapers.current : ""
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        brightness: Colors.isDark ? -0.1 : 0.05
        saturation: 0.2
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colors.scrim, Colors.isDark ? 0.45 : 0.15)
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.time
            font.pixelSize: 112
            font.weight: Font.DemiBold
            color: Colors.onSurface
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.day + ", " + Time.dateLong
            font.pixelSize: Appearance.font.title
            color: Colors.onSurfaceVariant
        }

        Item {
            Layout.preferredHeight: 28
        }

        RoundImage {
            id: face
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 88
            Layout.preferredHeight: 88
            radius: 44
            source: "file://" + Config.facePath
            visible: status === Image.Ready
        }
        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            visible: !face.visible
            text: "account_circle"
            size: 88
            fill: 1
            color: Colors.primary
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Quickshell.env("USER")
            font.pixelSize: Appearance.font.title
            font.weight: Font.Medium
        }

        // password field
        StyledRect {
            id: field

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.preferredWidth: 340
            Layout.preferredHeight: 56
            radius: Appearance.rounding.full
            color: Colors.surfaceContainerHighest
            border.width: root.context.showFailure ? 2 : input.activeFocus ? 2 : 0
            border.color: root.context.showFailure ? Colors.error : Colors.primary

            transform: Translate {
                id: shift
            }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: shift; property: "x"; to: -14; duration: 50 }
                NumberAnimation { target: shift; property: "x"; to: 14; duration: 80 }
                NumberAnimation { target: shift; property: "x"; to: -10; duration: 70 }
                NumberAnimation { target: shift; property: "x"; to: 0; duration: 60 }
            }

            Connections {
                target: root.context
                function onFailed() {
                    input.text = "";
                    shake.restart();
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 12
                spacing: 12

                MaterialIcon {
                    text: root.context.unlockInProgress ? "hourglass_top" : "lock"
                    size: 22
                    color: root.context.showFailure ? Colors.error : Colors.primary
                }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    focus: true
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    enabled: !root.context.unlockInProgress
                    color: Colors.onSurface
                    selectionColor: Colors.primary
                    selectedTextColor: Colors.onPrimary
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.bodyLarge

                    onTextChanged: root.context.currentText = text
                    onAccepted: root.context.tryUnlock()

                    StyledText {
                        anchors.fill: parent
                        visible: input.text === ""
                        text: root.context.showFailure ? "Wrong password" : "Password"
                        color: root.context.showFailure ? Colors.error : Colors.onSurfaceVariant
                        font.pixelSize: Appearance.font.bodyLarge
                    }

                    Component.onCompleted: forceActiveFocus()
                }

                IconButton {
                    icon: "arrow_forward"
                    variant: "filled"
                    size: 40
                    onClicked: root.context.tryUnlock()
                }
            }
        }
    }

    // keep typing even if focus drifted
    Keys.onPressed: event => {
        if (!input.activeFocus && event.text !== "")
            input.forceActiveFocus();
    }
}
