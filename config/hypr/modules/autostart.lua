local V = require("modules.variables")

hl.on("hyprland.start", function()
    -- Make the session environment visible to systemd user units / D-Bus activated apps
    -- (the polkit agent unit needs WAYLAND_DISPLAY, so it starts only after the import succeeded)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user start hyprpolkitagent.service")

    -- Make sure colours exist before the shell starts, then launch it
    hl.exec_cmd("material-theme init")
    hl.exec_cmd(V.shell)

    -- Services
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
