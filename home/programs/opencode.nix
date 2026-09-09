{
  config,
  pkgs,
  lib,
  opencode,
  ...
}:
let
  opencodeSecret = ../../secrets/opencode/opencode.json;
in
{
  sops.secrets = lib.mkIf (pkgs.lib.pathExists opencodeSecret) {
    "opencode/opencode.json" = {
      sopsFile = opencodeSecret;
      format = "json";
      key = "";
      path = "${config.home.homeDirectory}/.config/opencode/opencode.json";
      mode = "0600";
    };
  };

  home.packages = [
    opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.configFile = {
    "opencode/agents" = {
      source = ../config/opencode/agents;
      recursive = true;
    };
    "opencode/skills" = {
      source = ../config/opencode/skills;
      recursive = true;
    };
    "opencode/AGENTS.md".source = ../config/opencode/AGENTS.md;
  };
}
