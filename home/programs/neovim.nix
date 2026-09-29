{ nvim-config, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = false;
    withRuby = false;
  };

  xdg.configFile."nvim".source = nvim-config;
}
