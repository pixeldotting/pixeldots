pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight via brightnessctl. `changed` fires for every external or internal change so the OSD can react.
Singleton {
    id: root

    property real value: 0      // 0..1
    property bool available: false

    signal changed

    function set(fraction: real): void {
        const f = Math.max(0.01, Math.min(1, fraction));
        value = f;
        Quickshell.execDetached(["brightnessctl", "set", Math.round(f * 100) + "%"]);
        changed();
    }

    function change(percent: int): void {
        set(value + percent / 100);
    }

    function refresh(): void {
        if (!getter.running)
            getter.running = true;
    }

    Process {
        id: getter
        command: ["brightnessctl", "-m", "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // machine format: device,class,current,percent%,max
                const parts = text.trim().split(",");
                if (parts.length >= 5) {
                    const v = parseInt(parts[3]) / 100;
                    root.available = !isNaN(v);
                    if (root.available)
                        root.value = v;
                }
            }
        }
    }

    // pick up changes made by keybinds that bypass the shell
    Timer {
        interval: 4000
        running: root.available
        repeat: true
        onTriggered: root.refresh()
    }
}
