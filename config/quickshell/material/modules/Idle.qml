import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Idle chain: lock -> screen off -> suspend. Timeouts in seconds, 0 disables a step.
// Respects idle inhibitors (video players, fullscreen apps via the Hyprland window rule).
Scope {
    IdleMonitor {
        enabled: Config.lockTimeout > 0
        timeout: Config.lockTimeout
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Lockscreen.lock();
        }
    }

    IdleMonitor {
        enabled: Config.dpmsTimeout > 0
        timeout: Config.dpmsTimeout
        respectInhibitors: true
        onIsIdleChanged: Hypr.dpms(!isIdle)
    }

    IdleMonitor {
        enabled: Config.suspendTimeout > 0
        timeout: Config.suspendTimeout
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Quickshell.execDetached(["systemctl", "suspend"]);
        }
    }
}
