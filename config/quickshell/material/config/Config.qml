pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User preferences: ~/.config/material/shell.json (optional; any missing key uses its default).
// Example: { "workspaces": 8, "weatherLocation": "Tashkent", "lockTimeout": 600 }
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    readonly property alias workspaces: adapter.workspaces
    readonly property alias use24h: adapter.use24h
    readonly property alias weatherLocation: adapter.weatherLocation
    readonly property alias terminal: adapter.terminal
    readonly property alias notifTimeout: adapter.notifTimeout
    readonly property alias lockTimeout: adapter.lockTimeout
    readonly property alias dpmsTimeout: adapter.dpmsTimeout
    readonly property alias suspendTimeout: adapter.suspendTimeout
    readonly property alias pamService: adapter.pamService
    readonly property string wallpaperDir: expand(adapter.wallpaperDir)
    readonly property string facePath: home + "/.face"

    function expand(p: string): string {
        return p.startsWith("~") ? home + p.slice(1) : p;
    }

    FileView {
        path: root.home + "/.config/material/shell.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: adapter

            property int workspaces: 5
            property bool use24h: true
            property string weatherLocation: ""
            property string terminal: "kitty"
            property string wallpaperDir: "~/Pictures/Wallpapers"
            property int notifTimeout: 6000
            // seconds of inactivity; 0 disables
            property int lockTimeout: 300
            property int dpmsTimeout: 600
            property int suspendTimeout: 1800
            // PAM service used by the lock screen ("login" exists on every NixOS system)
            property string pamService: "login"
        }
    }
}
