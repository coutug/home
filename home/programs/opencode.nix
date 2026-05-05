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
    "opencode/prompts/build.md".source = ../config/opencode/build.md;
    "opencode/prompts/plan.md".source = ../config/opencode/plan.md;
    "opencode/prompts/teacher.md".source = ../config/opencode/teacher.md;
    "opencode/prompts/dashboard-builder.md".source = ../config/opencode/prompts/dashboard-builder.md;

    "opencode/commands/build-dashboard.md".source = ../config/opencode/commands/build-dashboard.md;

    "opencode/skills/build-dashboard/SKILL.md".source =
      ../config/opencode/skills/build-dashboard/SKILL.md;
  };
}
