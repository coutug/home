# Run without activation: nix build --impure --no-link --file tests/tmux-atuin.nix
# Then run <output>/run-tests for disposable tmux runtime checks outside the sandbox.
{
  flake ? builtins.getFlake (toString ../.),
}:
let
  pkgs = flake.homeConfigurations.laptop.pkgs;
  lib = pkgs.lib;
  home = flake.inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../home/programs/tmux.nix
      ../home/programs/atuin.nix
      {
        home.username = "test";
        home.homeDirectory = "/home/test";
        home.stateVersion = "25.05";
      }
    ];
  };
  pluginPaths = config: map (p: (p.plugin or p).rtp) config.programs.tmux.plugins;
  checkProfile =
    config:
    assert config.programs.tmux.enable;
    assert config.programs.tmux.sensibleOnTop;
    assert builtins.length (pluginPaths config) == 5;
    assert builtins.length (lib.unique (pluginPaths config)) == 5;
    assert config.programs.atuin.settings.auto_sync == false;
    assert config.programs.atuin.settings.theme.name == "marine";
    assert config.programs.atuin.themes == { };
    assert
      config.home.file.".tmux.conf".text == ''
        source-file "${config.xdg.configHome}/tmux/tmux.conf"
      '';
    true;
  config = home.config;
  testData = pkgs.writeText "tmux-atuin-test-data.json" (
    builtins.toJSON {
      plugins = pluginPaths config;
      sensible = pkgs.tmuxPlugins.sensible.rtp;
      tmuxConfig = config.xdg.configFile."tmux/tmux.conf".source;
      legacyConfig = config.home.file.".tmux.conf".text;
      atuinConfig = config.xdg.configFile."atuin/config.toml".source;
      wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
      xclip = "${pkgs.xclip}/bin/xclip";
      path = lib.makeBinPath [
        pkgs.tmux
        pkgs.atuin
        pkgs.bash
        pkgs.coreutils
        pkgs.gnused
        pkgs.gnugrep
        pkgs.gawk
        pkgs.findutils
      ];
    }
  );
  runner = pkgs.writeShellScript "tmux-atuin-tests" ''
    exec ${pkgs.python3}/bin/python3 ${./tmux-atuin.py} ${testData} "$@"
  '';
in
assert checkProfile config;
assert lib.all (name: checkProfile flake.homeConfigurations.${name}.config) [
  "laptop"
  "desktop"
];
pkgs.runCommand "tmux-atuin-regression"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.tmux
      pkgs.atuin
    ];
  }
  ''
    # Upstream plugin shebangs use /usr/bin/env, absent from the Nix sandbox.
    ${runner} --config-only
    mkdir -p "$out"
    ln -s ${runner} "$out/run-tests"
  ''
