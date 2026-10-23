local V   = require("modules.variables")
local mod = V.mod

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

----------------------------------------------------------------------
-- Apps
----------------------------------------------------------------------
hl.bind(mod .. " + Return",         exec(V.terminal))
hl.bind(mod .. " + T",              exec(V.terminal))
hl.bind(mod .. " + W",              exec(V.browser))
hl.bind(mod .. " + E",              exec(V.fileManager))

----------------------------------------------------------------------
-- Shell (Quickshell IPC)
----------------------------------------------------------------------
hl.bind(mod .. " + Space",          V.qs("drawers", "toggle", "launcher"),      { description = "Launcher" })
hl.bind(mod .. " + D",              V.qs("drawers", "toggle", "dashboard"),     { description = "Dashboard" })
hl.bind(mod .. " + N",              V.qs("drawers", "toggle", "sidebar"),       { description = "Notifications" })
hl.bind(mod .. " + A",              V.qs("drawers", "toggle", "controlcenter"), { description = "Control center" })
hl.bind(mod .. " + SHIFT + W",      V.qs("drawers", "toggle", "wallpaper"),     { description = "Wallpaper picker" })
hl.bind(mod .. " + Escape",         V.qs("drawers", "toggle", "session"),       { description = "Session menu" })
hl.bind("CTRL + ALT + Delete",      V.qs("drawers", "toggle", "session"),       { description = "Session menu" })
hl.bind(mod .. " + L",              V.qs("lock", "lock"),                       { description = "Lock screen" })
hl.bind(mod .. " + SHIFT + N",      V.qs("notifs", "toggleDnd"),                { description = "Do not disturb" })
hl.bind(mod .. " + SHIFT + C",      V.qs("notifs", "clear"),                    { description = "Clear notifications" })
hl.bind(mod .. " + V",              V.qs("drawers", "launcherQuery", "':'"),    { description = "Clipboard history" })
hl.bind(mod .. " + SHIFT + R",      exec("pkill -x qs; " .. V.shell),           { description = "Restart shell" })

-- Theme
hl.bind(mod .. " + SHIFT + T",      exec("material-theme mode toggle"),         { description = "Toggle dark/light" })
hl.bind(mod .. " + CTRL + W",       exec("material-theme random"),              { description = "Random wallpaper" })

----------------------------------------------------------------------
-- Windows
----------------------------------------------------------------------
hl.bind(mod .. " + Q",              hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q",      hl.dsp.window.kill())
hl.bind(mod .. " + F",              hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + M",              hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))
hl.bind(mod .. " + SHIFT + Space",  hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",              hl.dsp.window.pin({ action = "toggle" }))
hl.bind(mod .. " + C",              hl.dsp.window.center())
hl.bind(mod .. " + J",              hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + G",              hl.dsp.group.toggle())
hl.bind("ALT + Tab",                hl.dsp.group.next())

-- Focus / move with arrows and vim keys
for _, d in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mod .. " + " .. d,            hl.dsp.focus({ direction = d }))
    hl.bind(mod .. " + SHIFT + " .. d,    hl.dsp.window.move({ direction = d }))
end

-- Resize (repeats while held)
local step = 40
hl.bind(mod .. " + CTRL + left",  hl.dsp.window.resize({ x = -step, y = 0,     relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + right", hl.dsp.window.resize({ x = step,  y = 0,     relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,     y = -step, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,     y = step,  relative = true }), { repeating = true })

-- Mouse: move / resize
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

----------------------------------------------------------------------
-- Workspaces
----------------------------------------------------------------------
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + ALT + " .. key,       hl.dsp.window.move({ workspace = i }))
    hl.bind(mod .. " + ALT + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + Page_Down",  hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + Page_Up",    hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mod .. " + S",          hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S",  hl.dsp.window.move({ workspace = "special:magic" }))

----------------------------------------------------------------------
-- Screenshots / tools (see scripts/ -> material-screenshot)
----------------------------------------------------------------------
hl.bind("Print",                    exec("material-screenshot region"))
hl.bind("SHIFT + Print",            exec("material-screenshot full"))
hl.bind("CTRL + Print",             exec("material-screenshot window"))
hl.bind(mod .. " + Print",          exec("hyprpicker -a"))

----------------------------------------------------------------------
-- Media / hardware keys (work even if the shell is down)
----------------------------------------------------------------------
local lockedRepeat = { repeating = true, locked = true }
local locked       = { locked = true }

hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), lockedRepeat)
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"), lockedRepeat)
hl.bind("XF86AudioMute",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     locked)
hl.bind("XF86AudioMicMute",     exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   locked)

hl.bind("XF86MonBrightnessUp",
    exec(V.ipc("brightness", "up", "5") .. " || brightnessctl set 5%+"),  lockedRepeat)
hl.bind("XF86MonBrightnessDown",
    exec(V.ipc("brightness", "down", "5") .. " || brightnessctl set 5%-"), lockedRepeat)

hl.bind("XF86AudioPlay",  exec("playerctl play-pause"), locked)
hl.bind("XF86AudioPause", exec("playerctl play-pause"), locked)
hl.bind("XF86AudioNext",  exec("playerctl next"),       locked)
hl.bind("XF86AudioPrev",  exec("playerctl previous"),   locked)
