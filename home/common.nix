{
  config,
  pkgs,
  lib,
  nixgl,
  sops-nix,
  opencode,
  ...
}:
let
  codiumExtensionsFile = ./config/code/extensions.list;
  codiumExtensions = pkgs.lib.filter (s: s != "") (
    map pkgs.lib.strings.trim (pkgs.lib.splitString "\n" (builtins.readFile codiumExtensionsFile))
  );
  backupScript = builtins.readFile ./config/code/scripts/backup-vsconfigs.sh;
  syncScript = builtins.readFile ./config/code/scripts/sync-vscodium-extensions.sh;
in
{
  targets.genericLinux.enable = true;

  targets.genericLinux.nixGL = {
    packages = nixgl.packages.${pkgs.stdenv.hostPlatform.system}; # you must set this or everything will be a noop
    defaultWrapper = "mesa"; # choose from options
  };

  imports = [
    sops-nix.homeManagerModules.sops
    ./programs/atuin.nix
    ./programs/bat.nix
    ./programs/fzf.nix
    ./programs/home-manager.nix
    ./programs/htop.nix
    ./programs/k9s.nix
    ./programs/obs-studio.nix
    ./programs/zsh.nix
    ./programs/wezterm.nix
    ./programs/zoxide.nix
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  sops.secrets =
    let
      codexSecret = ../secrets/codex/config.toml;
      opencodeSecret = ../secrets/opencode/opencode.json;
      kubeconfigNames = builtins.attrNames (builtins.readDir ../secrets/kubeconfig);
      mkSecret = filename: {
        name = "kubeconfig/${filename}";
        value = {
          sopsFile = ../secrets/kubeconfig/${filename};
          format = "yaml";
          key = "";
          path = "${config.home.homeDirectory}/.kube/kubeconfig/${filename}";
          mode = "0644";
        };
      };
    in
    builtins.listToAttrs (map mkSecret kubeconfigNames)
    // (
      if pkgs.lib.pathExists codexSecret then
        {
          "codex/config.toml" = {
            sopsFile = codexSecret;
            format = "binary";
            key = "";
            path = "${config.home.homeDirectory}/.codex/config.toml";
            mode = "0600";
          };
        }
      else
        { }
    )
    // (
      if pkgs.lib.pathExists opencodeSecret then
        {
          "opencode/opencode.json" = {
            sopsFile = opencodeSecret;
            format = "json";
            key = "";
            path = "${config.home.homeDirectory}/.config/opencode/opencode.json";
            mode = "0600";
          };
        }
      else
        { }
    );

  home = {
    username = "gabriel";
    homeDirectory = "/home/gabriel";
    stateVersion = "25.05";

    sessionVariables = {
      EDITOR = "nvim";
      WINEFSYNC = 1; # Optimize vst performance
      BUN_INSTALL = "${config.home.homeDirectory}/.bun";
      CODEX_HOME = "${config.home.homeDirectory}/.codex";
    };

    sessionPath = pkgs.lib.mkAfter [
      "${config.home.homeDirectory}/.bun/bin"
      "${config.home.homeDirectory}/go/bin"
    ];

    packages = with pkgs; [
      augeas
      act
      age
      antigravity
      argocd
      # bluez
      # bluez-tools
      # codex # installed by yay as well
      crane
      curlie
      cilium-cli
      # discount
      dhcpcd
      duf
      etcd
      # fd #TODO dependency
      fluxcd
      jellyfin-ffmpeg
      # fwupd
      # fwupd-efi
      github-cli
      gptfdisk
      go
      go-jsonnet
      helmfile
      hey
      imagemagick
      # jq #TODO dependency
      # kdePackages.ark
      # kdePackages.bluedevil
      # kdePackages.okular
      keepassxc
      kind
      kopia
      kubectl
      kubie
      kubeconform
      kubelogin-oidc
      kubectl-df-pv
      kubectl-linstor
      kubectl-rook-ceph
      kubernetes-helm
      kustomize
      kyverno
      k0sctl
      lazydocker
      lazygit
      libguestfs
      libewf
      lrzip
      lzop
      man
      meslo-lgs-nf
      minikube
      musescore
      nix-zsh-completions
      nixfmt-rfc-style
      nil
      nmap
      poppler
      qbittorrent-enhanced
      resvg
      rclone
      # ripgrep #TODO dependency
      rsync
      rustup
      sleuthkit
      solaar
      sops
      spotify
      supermin
      squashfsTools
      strace
      syslinux
      tealdeer
      traceroute
      tree
      (opencode.packages.${pkgs.stdenv.hostPlatform.system}.default)
      opentofu
      tmuxp
      tmux
      trivy
      vector
      velero
      vscodium
      vesktop
      vim
      vlc
      yara
      yay
      yazi
      yq-go
      zellij
      zoom-us
      nixos-anywhere
      zsh-powerlevel10k
    ];

    file = {
      ".tmux.conf".source = ./config/tmux.conf;
      ".kube/kubie.yaml".source = ./config/kubie.yaml;
      ".ssh/config".source = ./config/ssh/config;
    };

    activation = {
      backupVSConfigs = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
        set -euo pipefail
        export HOME="${config.home.homeDirectory}"
        timestamp="$(date +%s)"
        backup_ext=".bak.$timestamp"

        ${backupScript}
      '';

      syncVSCodiumExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              set -euo pipefail
              export HOME="${config.home.homeDirectory}"

              desired_exts="$(cat <<'EOF'
        ${pkgs.lib.concatMapStringsSep "\n" (ext: ext) codiumExtensions}
        EOF
        )"

              codium_bin="${pkgs.vscodium}/bin/codium"

              ${syncScript}
      '';
    };
  };

  nixpkgs.config.allowUnfree = true;

  xdg.configFile = {
    "Code/User/settings.json".source = ./config/code/user/settings.json;
    "Code/User/keybindings.json".source = ./config/code/user/keybindings.json;

    "VSCodium/User/settings.json".source = ./config/code/user/settings.json;
    "VSCodium/User/keybindings.json".source = ./config/code/user/keybindings.json;

    "tmuxp/kmux.yml".source = ./config/kmux.yml;
  };
}
