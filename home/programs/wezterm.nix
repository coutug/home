{
  config,
  pkgs,
  ...
}:
let
  backend-wezterm = pkgs.fetchFromGitHub {
    owner = "smart-splits-nvim";
    repo = "backend-wezterm";
    rev = "ae840db696791f638c190c3e0534d2ddfcd5e6a7";
    hash = "sha256-9kDZAoYqQMtSGAE9w70UtkW/DLUmmwVAwCxDxk8om1E=";
  };
in
{
  programs.wezterm = {
    package = (config.lib.nixGL.wrap pkgs.wezterm);
    enable = true;
    enableZshIntegration = true;
    extraConfig = ''
      local config = wezterm.config_builder()
      package.path = package.path .. ';${backend-wezterm}/plugin/?.lua;${backend-wezterm}/plugin/?/init.lua'
      local smart_splits = dofile('${backend-wezterm}/plugin/init.lua')
      local equalize_panes = dofile('${../config/wezterm/equalize_panes.lua}')
      local act = wezterm.action

      -- Leader key
      config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

      config.colors = dofile(wezterm.config_dir .. "/cyberdream.lua")
      config.window_background_opacity = 0.80

      config.keys = {
        -- Splits (dans le domaine du pane courant)
        { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },    -- haut/bas
        { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) }, -- gauche/droite

        -- Tabs: new / rename / workspace
        { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
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
        { key = "=", mods = "LEADER", action = wezterm.action_callback(equalize_panes) },
        { key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
        { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
        { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
        { key = "x", mods = "CTRL", action = act.CloseCurrentPane({ confirm = true }) },
        { key = "x", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
        {
          key = "v", mods = "CTRL",
          action = wezterm.action_callback(function(window, pane)
            if pane:get_user_vars().IS_NVIM == "true" then
              window:perform_action(act.SendKey({ key = "v", mods = "CTRL" }), pane)
            else
              window:perform_action(act.ActivateCopyMode, pane)
            end
          end),
        },
      }
      for i = 1, 9 do
        table.insert(config.keys, {
          key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1),
        })
      end

      smart_splits.apply_to_config(config, {
        modifiers = { resize = 'CTRL|SHIFT' },
      })

      -- Keep resize handling on WezTerm, even while Neovim is active.
      local resize_directions = { h = "Left", j = "Down", k = "Up", l = "Right" }
      for _, binding in ipairs(config.keys) do
        if binding.mods == "CTRL|SHIFT" and resize_directions[binding.key] then
          binding.action = act.AdjustPaneSize({ resize_directions[binding.key], 3 })
        end
      end
      return config
    '';
  };

  xdg.configFile."wezterm/cyberdream.lua".source = ../config/wezterm/cyberdream.lua;
}
