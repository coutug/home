# Build only shell files and command dependencies; never activate a profile.
# nix build --impure --no-link --file tests/zsh-shell.nix
let
  flake = builtins.getFlake (toString ../.);
  inherit (flake.inputs.nixpkgs) lib;
  pkgs = import flake.inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  homes = lib.mapAttrsToList (_: value: value.config) flake.homeConfigurations;
  servers = lib.mapAttrsToList (
    _: value: value.config.home-manager.users.gabriel
  ) flake.nixosConfigurations;
  server = builtins.head servers;
  syntaxChecks = lib.concatMapStringsSep "\n" (
    config: "zsh -n ${config.home.file."./.zshrc".source}"
  ) (homes ++ servers);
  # Explicit executable names catch package-name/CLI-name differences.
  dependencies = with pkgs; [
    [
      coreutils
      "ls"
    ]
    [
      eza
      "eza"
    ]
    [
      git
      "git"
    ]
    [
      gnugrep
      "grep"
    ]
    [
      gnused
      "sed"
    ]
    [
      less
      "less"
    ]
    [
      procps
      "watch"
    ]
    [
      systemd
      "systemctl"
    ]
    [
      bc
      "bc"
    ]
    [
      docker-client
      "docker"
    ]
    [
      fzf
      "fzf"
    ]
    [
      lazydocker
      "lazydocker"
    ]
    [
      lazygit
      "lazygit"
    ]
    [
      minikube
      "minikube"
    ]
    [
      pacman
      "pacman"
    ]
    [
      terraform
      "terraform"
    ]
    [
      yay
      "yay"
    ]
    [
      yazi
      "yazi"
    ]
    [
      bash
      "bash"
    ]
    [
      curl
      "curl"
    ]
    [
      fluxcd
      "flux"
    ]
    [
      jq
      "jq"
    ]
    [
      kubeconform
      "kubeconform"
    ]
    [
      kubectl
      "kubectl"
    ]
    [
      kubernetes-helm
      "helm"
    ]
    [
      kubie
      "kubie"
    ]
    [
      kustomize
      "kustomize"
    ]
    [
      openssh
      "ssh"
    ]
    [
      flake.inputs.opencode.packages.x86_64-linux.default
      "opencode"
    ]
    [
      (builtins.head homes).programs.neovim.finalPackage
      "nvim"
    ]
    [
      (builtins.head homes).programs.home-manager.package
      "home-manager"
    ]
  ];
in
pkgs.runCommand "zsh-layer-shell-checks" { nativeBuildInputs = [ pkgs.zsh ]; } ''
  ${syntaxChecks}
  ${lib.concatMapStringsSep "\n" (
    pair: "test -x ${lib.getExe' (builtins.head pair) (builtins.elemAt pair 1)}"
  ) dependencies}
  # Source the generated server shell in a disposable home, not the live one.
  mkdir -p "$TMPDIR/home/.zsh/plugins"
  ln -s ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k "$TMPDIR/home/.zsh/plugins/zsh-powerlevel10k"
  ln -s ${server.home.file.".p10k.zsh".source} "$TMPDIR/home/.p10k.zsh"
  substitute ${server.home.file."./.zshrc".source} "$TMPDIR/home/server.zsh" \
    --replace-fail ${lib.escapeShellArg server.home.homeDirectory} "$TMPDIR/home"
  env -i HOME="$TMPDIR/home" USER=shell-test TERM=dumb \
    PATH=${
      lib.makeBinPath (
        with pkgs;
        [
          coreutils
          eza
          git
          gnugrep
          gnused
          less
          procps
          systemd
        ]
      )
    } \
    ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh \
    ZSH_CACHE_DIR="$TMPDIR/home/cache" ZSH_COMPDUMP="$TMPDIR/home/.zcompdump" \
    SERVER_PROMPT=1 POWERLEVEL9K_DISABLE_GITSTATUS=true \
    ${pkgs.zsh}/bin/zsh -f -c '
      source "$HOME/server.zsh" || exit 1
      [[ $aliases[ll] == "eza -la --git" && $aliases[g] == git ]] || exit 1
      for name in y yn yc pkgls mk ld lg nv nv-dev oc kc kb kval; do
        (( ! $+aliases[$name] )) || exit 1
      done
      for name in kmux get-clusters get-nodes pvc-usage tx yy; do
        (( ! $+functions[$name] )) || exit 1
      done
    '
  touch "$out"
''
