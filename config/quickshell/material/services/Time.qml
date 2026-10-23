pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    readonly property alias date: clock.date

    readonly property string hours: Qt.formatDateTime(clock.date, Config.use24h ? "HH" : "hh")
    readonly property string minutes: Qt.formatDateTime(clock.date, "mm")
    readonly property string time: Qt.formatDateTime(clock.date, Config.use24h ? "HH:mm" : "hh:mm AP")
    readonly property string day: Qt.formatDateTime(clock.date, "dddd")
    readonly property string dateLong: Qt.formatDateTime(clock.date, "d MMMM yyyy")

    // plain ints so bindings only re-evaluate when the value actually changes
    readonly property int dayNum: clock.date.getDate()
    readonly property int monthNum: clock.date.getMonth()
    readonly property int yearNum: clock.date.getFullYear()

    readonly property string greeting: {
        const h = clock.date.getHours();
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
