import QtQuick
import Quickshell
import Quickshell.Widgets

IconImage {
    property string name

    implicitSize: 32
    source: name.startsWith("/") ? "file://" + name : Quickshell.iconPath(name, "application-x-executable")
}
