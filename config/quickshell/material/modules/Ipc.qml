import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// `qs -c material ipc call <target> <function> [args]` — used by the Hyprland keybinds.
Scope {
    IpcHandler {
        target: "drawers"

        function toggle(name: string): void {
            Visibilities.toggle(name);
        }
        function open(name: string): void {
            Visibilities.open(name);
        }
        function close(): void {
            Visibilities.close();
        }
        function launcherQuery(query: string): void {
            Visibilities.openLauncher(query);
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            Lockscreen.lock();
        }
    }

    IpcHandler {
        target: "brightness"

        function up(percent: int): void {
            Brightness.change(percent);
        }
        function down(percent: int): void {
            Brightness.change(-percent);
        }
    }

    IpcHandler {
        target: "notifs"

        function toggleDnd(): void {
            Notifs.toggleDnd();
        }
        function clear(): void {
            Notifs.clear();
        }
    }

    IpcHandler {
        target: "theme"

        function random(): void {
            Wallpapers.random();
        }
        function toggleMode(): void {
            Wallpapers.toggleMode();
        }
    }
}
