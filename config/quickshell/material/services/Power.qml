pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Battery (UPower) + power profile (power-profiles-daemon).
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool hasBattery: device?.isLaptopBattery ?? false
    readonly property real percent: (device?.percentage ?? 0) * 100
    readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged
    readonly property bool low: hasBattery && !charging && percent <= 15

    readonly property string icon: {
        if (!hasBattery)
            return "power";
        if (charging)
            return "battery_charging_full";
        const p = percent;
        return p >= 95 ? "battery_full" : p >= 80 ? "battery_6_bar" : p >= 65 ? "battery_5_bar" : p >= 50 ? "battery_4_bar" : p >= 35 ? "battery_3_bar" : p >= 20 ? "battery_2_bar" : p >= 10 ? "battery_1_bar" : "battery_alert";
    }

    // "performance" | "balanced" | "power-saver" ("" when power-profiles-daemon is missing)
    property string profile: ""
    readonly property bool profilesAvailable: profile !== ""

    function setProfile(p: string): void {
        profile = p;
        Quickshell.execDetached(["powerprofilesctl", "set", p]);
    }

    Process {
        id: getProfile
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.profile = text.trim()
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: getProfile.running = true
    }
}
