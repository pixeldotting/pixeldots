//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell
import qs.modules
import qs.modules.background
import qs.modules.bar
import qs.modules.lock
import qs.services

ShellRoot {
    // Singletons are lazy: reference the ones that must run from startup.
    Component.onCompleted: {
        Notifs.init();
        Wallpapers.init();
    }

    Background {}
    Bar {}
    Drawers {}
    Lock {}
    Idle {}
    Ipc {}
}
