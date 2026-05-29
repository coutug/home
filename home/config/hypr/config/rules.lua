hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "wezterm-workspace",
    match = { class = "org.wezfurlong.wezterm" },

    workspace = "1",
})

hl.window_rule({
    name  = "brave-workspace",
    match = { class = "brave-browser" },

    workspace = "2",
})

hl.window_rule({
    name  = "obsidian-workspace",
    match = { class = "obsidian" },

    workspace = "3",
})
