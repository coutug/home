{ config, pkgs, ... }:
{
  programs.wezterm = {
    package = (config.lib.nixGL.wrap pkgs.wezterm);
    enable = true;
    enableZshIntegration = true;
    extraConfig = ''
      local config = wezterm.config_builder()
      local act = wezterm.action

      -- Leader key
      config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

      config.color_scheme = "Builtin Solarized Dark"

      -- config.window_decorations = "RESIZE"
      -- config.window_padding = { left = 6, right = 6, top = 4, bottom = 4 }
      -- config.hide_tab_bar_if_only_one_tab = false
      -- config.use_fancy_tab_bar = false

      -- Key tables utiles (optionnel mais clair)
      config.key_tables = {
        resize_pane = {
          { key = "h", action = act.AdjustPaneSize({ "Left",  3 }) },
          { key = "j", action = act.AdjustPaneSize({ "Down",  3 }) },
          { key = "k", action = act.AdjustPaneSize({ "Up",    3 }) },
          { key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
          -- Quitter le mode resize
          { key = "Escape", action = "PopKeyTable" },
          { key = "q",      action = "PopKeyTable" },
        },
      }

      -- Raccourcis centrés sur splits / navigation
      config.keys = {
        -- Splits (dans le domaine du pane courant)
        { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },    -- haut/bas
        { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) }, -- gauche/droite

        -- Fermer pane / tab
        { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
        { key = "X", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },

        -- Naviguer entre panes (style Vim)
        { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
        { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
        { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
        { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

        -- Redimensionner: entrer en mode resize avec Leader + r
        { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

        -- Tabs: nouveau / suivant / précédent / renommer
        { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
        { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
        { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
        {
          key = ",",
          mods = "LEADER",
          action = act.PromptInputLine({
            description = "Renommer l'onglet",
            action = wezterm.action_callback(function(window, pane, line)
              if line then window:active_tab():set_title(line) end
            end),
          }),
        },
          -- Workspaces: lanceur dédié
        { key = "w", mods = "LEADER",
          action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },

        -- Palette de commandes (pratique pour retrouver des actions)
        { key = "P", mods = "LEADER|SHIFT", action = act.ActivateCommandPalette },

        -- Raccourcis utiles
        { key = "f", mods = "LEADER", action = act.ToggleFullScreen },
        { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
      }
      return config
    '';
  };
}
