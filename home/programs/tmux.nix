{
  config,
  pkgs,
  lib,
  ...
}:
let
  clipboard = pkgs.writeShellScript "tmux-copy" ''
    if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
      exec ${pkgs.wl-clipboard}/bin/wl-copy
    elif [ -n "''${DISPLAY:-}" ]; then
      # xclip forks; do not let its child keep tmux's output pipe open.
      exec ${pkgs.xclip}/bin/xclip -selection clipboard -in >/dev/null
    else
      echo "tmux-copy: no Wayland or X11 display available" >&2
      exit 1
    fi
  '';
  themepack = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "themepack";
    version = "unstable-2019-12-22";
    src = pkgs.fetchFromGitHub {
      owner = "jimeh";
      repo = "tmux-themepack";
      rev = "7c59902f64dcd7ea356e891274b21144d1ea5948";
      hash = "sha256-c5EGBrKcrqHWTKpCEhxYfxPeERFrbTuDfcQhsUAbic4=";
    };
  };
in
{
  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    plugins = with pkgs.tmuxPlugins; [
      resurrect
      {
        plugin = yank;
        extraConfig = ''
          set -g @override_copy_command '${clipboard}'
          set -g @yank_selection 'clipboard'
          set -g @yank_selection_mouse 'clipboard'
        '';
      }
      themepack
      continuum
      tmux-fzf
    ];
    # Apply personal bindings last so plugin defaults cannot replace them.
    extraConfig = lib.replaceStrings [ "@clipboard@" ] [ "${clipboard}" ] (
      builtins.readFile ../config/tmux.conf
    );
  };

  # Keep the existing reload binding and external users of ~/.tmux.conf working.
  home.file.".tmux.conf".text = ''
    source-file "${config.xdg.configHome}/tmux/tmux.conf"
  '';
}
