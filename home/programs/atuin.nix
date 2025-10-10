{ ... }:
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    daemon.enable = true;
    themes."marineTheme"."marineTheme".name = "marine"; # fonctionne pas
    settings = {
      auto_sync = true;
      sync_frequency = "20m";
      style = "compact";
      update_check = false;
      invert = true;
      enter_accept = true;
    };
  };
}
