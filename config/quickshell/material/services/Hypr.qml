pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Thin wrapper over Hyprland. Since 0.55 the config language is Lua, so every dispatcher is
// issued as a Lua expression through `hyprctl dispatch '<lua>'`.
Singleton {
    id: root

    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property string focusedMonitorName: focusedMonitor?.name ?? ""

    function dispatch(lua: string): void {
        Quickshell.execDetached(["hyprctl", "dispatch", lua]);
    }

    function eval(lua: string): void {
        Quickshell.execDetached(["hyprctl", "eval", lua]);
    }

    function focusWorkspace(id: var): void {
        dispatch("hl.dsp.focus({ workspace = " + (typeof id === "string" ? '"' + id + '"' : id) + " })");
    }

    function dpms(on: bool): void {
        dispatch('hl.dsp.dpms({ action = "' + (on ? "on" : "off") + '" })');
    }

    // Game mode: drop animations, blur, shadows and gaps. Turning it off reloads the Lua config.
    property bool gameMode: false

    function toggleGameMode(): void {
        gameMode = !gameMode;
        if (gameMode)
            eval("hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, shadow = { enabled = false } }, general = { gaps_in = 0, gaps_out = 0 } })");
        else
            Quickshell.execDetached(["hyprctl", "reload"]);
    }

    function isFocused(screen: var): bool {
        return screen && Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === screen.name;
    }
}
