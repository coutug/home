{ ... }:
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    daemon.enable = true;
    settings = {
      # Keep history local until a sync destination and filtering policy are approved.
      auto_sync = false;
      # Marine is built into the pinned Atuin version; no custom theme file is needed.
      theme.name = "marine";
      style = "compact";
      update_check = false;
      invert = true;
      enter_accept = true;
    };
  };
}
