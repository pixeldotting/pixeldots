import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// ext-session-lock-v1 lock screen. State lives in Lockscreen (so keybinds, idle and the session menu share it).
Scope {
    WlSessionLock {
        id: lock

        locked: Lockscreen.locked

        onLockedChanged: {
            if (!locked)
                Lockscreen.locked = false;
        }

        WlSessionLockSurface {
            color: Colors.surface

            LockSurface {
                anchors.fill: parent
                context: ctx
            }
        }
    }

    LockContext {
        id: ctx
        onUnlocked: Lockscreen.locked = false
    }
}
