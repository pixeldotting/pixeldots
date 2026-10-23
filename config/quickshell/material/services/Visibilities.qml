pragma Singleton

import QtQuick
import Quickshell

// Exactly one drawer is open at a time: "", "launcher", "dashboard", "sidebar",
// "controlcenter", "session", "wallpaper".
Singleton {
    id: root

    property string active: ""
    // text pre-filled into the launcher when it opens (e.g. ":" for clipboard history)
    property string launcherQuery: ""

    readonly property bool any: active !== ""
    readonly property bool wantsKeyboard: active === "launcher" || active === "session" || active === "wallpaper"

    function toggle(name: string): void {
        active = active === name ? "" : name;
        if (name !== "launcher")
            launcherQuery = "";
    }

    function open(name: string): void {
        active = name;
    }

    function openLauncher(query: string): void {
        launcherQuery = query;
        active = "launcher";
    }

    function close(): void {
        active = "";
        launcherQuery = "";
    }
}
