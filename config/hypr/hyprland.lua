-- ╭──────────────────────────────────────────────────────────╮
-- │  Material dots · Hyprland (Lua API, Hyprland >= 0.55)     │
-- │  Every concern lives in modules/*.lua; each required file │
-- │  runs in its own isolated scope, so shared values are     │
-- │  exchanged via return tables (see modules/variables.lua). │
-- ╰──────────────────────────────────────────────────────────╯

require("modules.env")
require("modules.monitors")
require("modules.input")
require("modules.look")
require("modules.animations")
require("modules.binds")
require("modules.rules")
require("modules.autostart")

-- Personal overrides: ~/.config/hypr/user.lua (never managed by the dots).
-- Missing file is fine; a *broken* one is reported instead of killing the session.
local ok, err = pcall(require, "user")
if not ok and not tostring(err):find("not found", 1, true) then
    hl.exec_cmd("notify-send -u critical 'Hyprland: user.lua failed' '" .. tostring(err):gsub("'", "") .. "'")
end
