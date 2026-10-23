-- Monitors. Default: every output at its preferred mode, auto placed.
-- Override in ~/.config/hypr/user.lua, e.g.
--   hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "0x0", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
