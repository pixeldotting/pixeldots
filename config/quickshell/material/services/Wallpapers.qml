pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Wallpaper + theme state (mirrors ~/.local/state/material/state.json, written by `material-theme`).
Singleton {
    id: root

    property string current: ""
    property string mode: "dark"
    property string variant: "scheme-tonal-spot"
    property var list: []

    readonly property var variants: [
        {
            id: "scheme-tonal-spot",
            name: "Tonal spot"
        },
        {
            id: "scheme-expressive",
            name: "Expressive"
        },
        {
            id: "scheme-vibrant",
            name: "Vibrant"
        },
        {
            id: "scheme-fidelity",
            name: "Fidelity"
        },
        {
            id: "scheme-content",
            name: "Content"
        },
        {
            id: "scheme-neutral",
            name: "Neutral"
        },
        {
            id: "scheme-monochrome",
            name: "Monochrome"
        },
        {
            id: "scheme-rainbow",
            name: "Rainbow"
        },
        {
            id: "scheme-fruit-salad",
            name: "Fruit salad"
        }
    ]

    function init(): void {
    }

    function setWallpaper(path: string): void {
        Quickshell.execDetached(["material-theme", "wallpaper", path]);
    }

    function random(): void {
        Quickshell.execDetached(["material-theme", "random"]);
    }

    function setMode(m: string): void {
        Quickshell.execDetached(["material-theme", "mode", m]);
    }

    function toggleMode(): void {
        setMode(mode === "dark" ? "light" : "dark");
    }

    function setVariant(v: string): void {
        Quickshell.execDetached(["material-theme", "variant", v]);
    }

    function rescan(): void {
        if (!scan.running)
            scan.running = true;
    }

    FileView {
        path: Config.home + "/.local/state/material/state.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.current = s.wallpaper ?? "";
                root.mode = s.mode ?? "dark";
                root.variant = s.variant ?? "scheme-tonal-spot";
            } catch (e) {
                console.warn("Wallpapers: invalid state.json (" + e + ")");
            }
        }
    }

    Process {
        id: scan
        command: ["find", "-L", Config.wallpaperDir, "-maxdepth", "2", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector {
            onStreamFinished: root.list = text.trim().split("\n").filter(s => s !== "").sort()
        }
    }

    Component.onCompleted: rescan()
}
