pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NetworkManager via nmcli.
Singleton {
    id: root

    property bool wifiEnabled: true
    property bool wifiConnected: false
    property bool ethernet: false
    property string ssid: ""
    property int strength: 0
    property var networks: []        // [{ ssid, signal, secure, active, known }]
    property string error: ""
    property bool busy: false

    readonly property bool connected: wifiConnected || ethernet

    readonly property string icon: {
        if (ethernet)
            return "lan";
        if (!wifiEnabled)
            return "wifi_off";
        if (!wifiConnected)
            return "signal_wifi_bad";
        return strength > 75 ? "signal_wifi_4_bar" : strength > 50 ? "network_wifi_3_bar" : strength > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }

    readonly property string summary: ethernet ? "Ethernet" : !wifiEnabled ? "Off" : wifiConnected ? ssid : "Not connected"

    // nmcli -t escapes ':' as '\:'
    function splitTerse(line: string): var {
        return line.replace(/\\:/g, "\u0001").split(":").map(s => s.replace(/\u0001/g, ":"));
    }

    function refresh(rescan: bool): void {
        devices.running = true;
        radio.running = true;
        knownProc.running = true;
        if (wifiEnabled) {
            listProc.command = ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", rescan ? "yes" : "no"];
            listProc.running = true;
        }
    }

    function toggleWifi(): void {
        const next = !wifiEnabled;
        wifiEnabled = next;
        Quickshell.execDetached(["nmcli", "radio", "wifi", next ? "on" : "off"]);
        settle.restart();
    }

    function connect(name: string, password: string): void {
        error = "";
        busy = true;
        connectProc.command = password ? ["nmcli", "device", "wifi", "connect", name, "password", password] : ["nmcli", "device", "wifi", "connect", name];
        connectProc.running = true;
    }

    function disconnect(): void {
        Quickshell.execDetached(["sh", "-c", "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"wifi\"{print $1}' | xargs -r -n1 nmcli device disconnect"]);
        settle.restart();
    }

    Timer {
        id: settle
        interval: 1500
        onTriggered: root.refresh(false)
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh(false)
    }

    // faster refresh + active rescan while the control centre is open
    Timer {
        interval: 6000
        running: Visibilities.active === "controlcenter"
        repeat: true
        onTriggered: root.refresh(true)
    }

    Connections {
        target: Visibilities
        function onActiveChanged() {
            if (Visibilities.active === "controlcenter")
                root.refresh(true);
        }
    }

    Process {
        id: devices
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let eth = false, wifi = false, name = "";
                for (const line of text.trim().split("\n")) {
                    const f = root.splitTerse(line);
                    if (f[1] !== "connected")
                        continue;
                    if (f[0] === "ethernet")
                        eth = true;
                    if (f[0] === "wifi") {
                        wifi = true;
                        name = f[2];
                    }
                }
                root.ethernet = eth;
                root.wifiConnected = wifi;
                if (wifi)
                    root.ssid = name;
            }
        }
    }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    property var _known: []

    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: root._known = text.trim().split("\n").map(s => s.replace(/\\:/g, ":"))
        }
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const f = root.splitTerse(line);
                    const name = f[1];
                    if (!name)
                        continue;
                    const entry = {
                        ssid: name,
                        signal: parseInt(f[2]) || 0,
                        secure: !!f[3] && f[3] !== "--",
                        active: f[0] === "*",
                        known: root._known.indexOf(name) !== -1
                    };
                    // keep the strongest entry per SSID
                    if (!seen[name] || seen[name].signal < entry.signal || entry.active) {
                        seen[name] = entry;
                    }
                }
                for (const k in seen)
                    out.push(seen[k]);
                out.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
                root.networks = out;
                const act = out.find(n => n.active);
                if (act) {
                    root.strength = act.signal;
                    root.ssid = act.ssid;
                }
            }
        }
    }

    Process {
        id: connectProc
        stderr: StdioCollector {
            id: connErr
        }
        onExited: code => {
            root.busy = false;
            if (code !== 0)
                root.error = connErr.text.trim().split("\n")[0] || "Connection failed";
            root.refresh(false);
        }
    }
}
