pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU / RAM / disk. Only polls while the dashboard is open.
Singleton {
    id: root

    property real cpu: 0       // 0..1
    property real memUsed: 0   // GiB
    property real memTotal: 0  // GiB
    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0
    property real disk: 0      // 0..1
    property real diskUsed: 0  // GiB
    property real diskTotal: 0 // GiB

    property var _prev: null

    Timer {
        interval: 2000
        running: Visibilities.active === "dashboard"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }

    Connections {
        target: Visibilities
        function onActiveChanged() {
            if (Visibilities.active === "dashboard")
                diskProc.running = true;
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const line = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = line[3] + (line[4] || 0);
            const total = line.reduce((a, b) => a + b, 0);
            if (root._prev) {
                const dTotal = total - root._prev.total;
                const dIdle = idle - root._prev.idle;
                if (dTotal > 0)
                    root.cpu = Math.max(0, Math.min(1, 1 - dIdle / dTotal));
            }
            root._prev = {
                total: total,
                idle: idle
            };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const get = key => parseInt((t.match(new RegExp(key + ":\\s+(\\d+)")) || [0, 0])[1]);
            const total = get("MemTotal");
            const avail = get("MemAvailable");
            root.memTotal = total / 1048576;
            root.memUsed = (total - avail) / 1048576;
        }
    }

    Process {
        id: diskProc
        command: ["df", "-B1", "--output=size,used", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")[1]?.trim().split(/\s+/).map(Number);
                if (f && f[0] > 0) {
                    root.diskTotal = f[0] / 1073741824;
                    root.diskUsed = f[1] / 1073741824;
                    root.disk = f[1] / f[0];
                }
            }
        }
    }
}
