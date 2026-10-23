hl.config({
    input = {
        kb_layout    = "us,ru",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "grp:alt_shift_toggle",
        kb_rules     = "",
        repeat_rate  = 35,
        repeat_delay = 250,
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
})

-- Three finger swipe switches workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
