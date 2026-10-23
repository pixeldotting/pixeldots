----------------------------------------------------------------------
-- Window rules
----------------------------------------------------------------------
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Small utility windows float and centre
local floaters = {
    "^(pavucontrol)$", "^(pwvucontrol)$", "^(org.pulseaudio.pavucontrol)$",
    "^(nm-connection-editor)$", "^(blueman-manager)$", "^(.blueman-manager-wrapped)$",
    "^(org.gnome.Calculator)$", "^(xdg-desktop-portal-gtk)$", "^(polkit-gnome-authentication-agent-1)$",
    "^(org.kde.polkit-kde-authentication-agent-1)$", "^(hyprpolkitagent)$",
}
for i, cls in ipairs(floaters) do
    hl.window_rule({
        name  = "float-" .. i,
        match = { class = cls },
        float = true,
        center = true,
    })
end

-- File chooser dialogs
hl.window_rule({
    name  = "file-dialogs",
    match = { title = "^(Open File|Save File|Save As|Open Folder|Choose .*|Select .*)$" },
    float = true,
    center = true,
    size  = { "monitor_w*0.55", "monitor_h*0.6" },
})

-- Picture in picture
hl.window_rule({
    name  = "pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
    size  = { "monitor_w*0.25", "monitor_h*0.25" },
    move  = "monitor_w-window_w-20 monitor_h-window_h-20",
})

-- Don't let anything sleep through a fullscreen video / game
hl.window_rule({
    name  = "idle-inhibit-fullscreen",
    match = { fullscreen = true },
    idle_inhibit = "fullscreen",
})

-- Media viewers stay opaque (no blur / transparency tricks)
hl.window_rule({
    name  = "opaque-media",
    match = { class = "^(mpv|vlc|org.gnome.Loupe|imv)$" },
    opaque = true,
})

----------------------------------------------------------------------
-- Layer rules (Quickshell namespaces are all "material-*")
----------------------------------------------------------------------
-- The shell animates itself; compositor animations would double up.
hl.layer_rule({ name = "shell-no-anim", match = { namespace = "^material-.*$" }, no_anim = true })
hl.layer_rule({ name = "shell-blur",    match = { namespace = "^material-(osd|notifs)$" }, blur = true, ignore_alpha = 0.3 })
