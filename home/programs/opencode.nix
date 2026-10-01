{
  config,
  pkgs,
  opencode,
  ...
}:
let
  opencodeSecretsDir = ../../secrets/opencode;
  opencodeSecrets = builtins.readDir opencodeSecretsDir;
  opencodeSecretNames = builtins.filter (name: opencodeSecrets.${name} == "regular") (
    builtins.attrNames opencodeSecrets
  );
  mkOpencodeSecret = name: {
    name = "opencode/${name}";
    value = {
      sopsFile = opencodeSecretsDir + "/${name}";
      format = "binary";
      key = "";
      path = "${config.home.homeDirectory}/.config/opencode/${name}";
      mode = "0600";
    };
  };
in
{
  sops.secrets = builtins.listToAttrs (map mkOpencodeSecret opencodeSecretNames);

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
    "opencode/opencode.jsonc".source = ../config/opencode/opencode.jsonc;
    "opencode/tui.jsonc".source = ../config/opencode/tui.jsonc;
  };
}
