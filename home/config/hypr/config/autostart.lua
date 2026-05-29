local programs = require("config.programs")

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")

    hl.exec_cmd(programs.terminal)
    hl.exec_cmd(programs.browser)
    hl.exec_cmd(programs.note)

    hl.exec_cmd("sleep 8 && hyprctl dispatch workspace 1")
end)
