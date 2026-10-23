-- Look & feel. Colours come from matugen (~/.config/hypr/colors.lua).
local ok, c = pcall(require, "colors")
if not ok or type(c) ~= "table" then
    c = require("modules.colors_fallback")
end

local function rgba(hex, alpha)
    return "rgba(" .. hex .. (alpha or "ff") .. ")"
end

hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 8,
        border_size      = 2,
        col = {
            active_border   = { colors = { rgba(c.primary), rgba(c.tertiary or c.secondary) }, angle = 45 },
            inactive_border = rgba(c.outline_variant, "aa"),
        },
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 18,
        rounding_power   = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 24,
            render_power = 3,
            color        = rgba(c.shadow, "55"),
        },
        blur = {
            enabled   = true,
            size      = 6,
            passes    = 3,
            vibrancy  = 0.1696,
            noise     = 0.02,
        },
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },
    master  = { new_status = "master" },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
    },
})
