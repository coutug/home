{
  config,
  pkgs,
  opencode,
  ...
}:
let
  engramRelease = builtins.fromJSON (builtins.readFile ./engram-version.json);
  engramVersion = engramRelease.version;
  engram = pkgs.stdenvNoCC.mkDerivation {
    pname = "engram";
    version = engramVersion;
    src = pkgs.fetchurl {
      url = "https://github.com/Gentleman-Programming/engram/releases/download/v${engramVersion}/engram_${engramVersion}_linux_amd64.tar.gz";
      hash = engramRelease.binaryHash;
    };
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 engram "$out/bin/engram"
    '';
    meta.platforms = [ "x86_64-linux" ];
  };
  engramPlugin = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Gentleman-Programming/engram/v${engramVersion}/plugin/opencode/engram.ts";
    hash = engramRelease.pluginHash;
  };
  engramCommand = "${engram}/bin/engram";
  engramPluginSource = builtins.readFile engramPlugin;
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
    engram
    (pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pyyaml ]))
  ];

  xdg.configFile = {
    "opencode/agents" = {
      source = ../config/opencode/agents;
      recursive = true;
    };
    "opencode/commands" = {
      source = ../config/opencode/commands;
      recursive = true;
    };
    "opencode/skills" = {
      source = ../config/opencode/skills;
      recursive = true;
    };
    "opencode/plugins" = {
      source = ../config/opencode/plugins;
      recursive = true;
    };
    "opencode/AGENTS.md".source = ../config/opencode/AGENTS.md;
    "opencode/plugins/engram.ts".text = builtins.replaceStrings
      [ ''?? "engram"'' ]
      [ ''?? "${engramCommand}"'' ]
      (assert pkgs.lib.hasInfix ''?? "engram"'' engramPluginSource; engramPluginSource);
    "opencode/opencode.jsonc".text = builtins.replaceStrings
      [ "@ENGRAM_COMMAND@" ]
      [ engramCommand ]
      (builtins.readFile ../config/opencode/opencode.jsonc);
    "opencode/cli.json".source = ../config/opencode/cli.json;
  };
}
