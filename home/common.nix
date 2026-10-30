{
  config,
  pkgs,
  lib,
  nixgl,
  sops-nix,
  ...
}:
{
  targets.genericLinux.enable = true;

  targets.genericLinux.nixGL = {
    packages = nixgl.packages.${pkgs.stdenv.hostPlatform.system}; # you must set this or everything will be a noop
    defaultWrapper = "mesa"; # choose from options
  };

  imports = [
    sops-nix.homeManagerModules.sops
    ./programs/atuin.nix
    ./programs/agent-orchestrator.nix
    ./programs/bat.nix
    ./programs/bottom.nix
    ./programs/fzf.nix
    ./programs/git.nix
    ./programs/home-manager.nix
    ./programs/htop.nix
    ./programs/k9s.nix
    ./programs/neovim.nix
    ./programs/obs-studio.nix
    ./programs/opencode.nix
    ./programs/zsh.nix
    ./programs/wezterm.nix
    ./programs/zoxide.nix
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  sops.secrets =
    let
      kubeconfigNames = builtins.attrNames (builtins.readDir ../secrets/kubeconfig);
      mkSecret = filename: {
        name = "kubeconfig/${filename}";
        value = {
          sopsFile = ../secrets/kubeconfig/${filename};
          format = "yaml";
          key = "";
          path = "${config.home.homeDirectory}/.kube/kubeconfig/${filename}";
          mode = "0600";
        };
      };
    in
    builtins.listToAttrs (map mkSecret kubeconfigNames);

  news.display = "silent";

  home = {
    username = "gabriel";
    homeDirectory = "/home/gabriel";
    stateVersion = "25.05";

    sessionVariables = {
      WINEFSYNC = 1; # Optimize vst performance
      BUN_INSTALL = "${config.home.homeDirectory}/.bun";
      OMO_AST_GREP_SG_PATH = "${config.home.homeDirectory}/.local/node_modules/@ast-grep/cli/sg";
      OPENCODE_ENABLE_PARALLEL = 1; # opencode web search
    };

    sessionPath = pkgs.lib.mkAfter [
      "${config.home.homeDirectory}/.bun/bin"
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/go/bin"
    ];

    packages = with pkgs; [
      act
      age
      argocd
      augeas
      cilium-cli
      clipboard-jh
      crane
      curlie
      dbeaver-bin
      dhcpcd
      duf
      dust
      etcd
      eza
      fabric-ai
      fluxcd
      fluxcd-operator
      fx
      github-cli
      gptfdisk
      go
      go-jsonnet
      gum
      hey
      imagemagick
      k0sctl
      keepassxc
      kind
      kubeconform
      kubectl
      kubectl-cnpg
      kubectl-df-pv
      kubectl-linstor
      kubectl-rook-ceph
      kubelogin-oidc
      kubernetes-helm
      kubie
      kustomize
      kyverno
      lazydocker
      lazygit
      libguestfs
      libewf
      lsd
      lrzip
      lzop
      man
      meslo-lgs-nf
      minikube
      navi
      nil
      nix-zsh-completions
      nixfmt
      nixos-anywhere
      nmap
      ntfs3g
      pi-coding-agent
      poppler
      p7zip
      qbittorrent-enhanced
      rclone
      resvg
      rsync
      rustup
      slack
      sleuthkit
      sops
      spotify
      squashfsTools
      ssh-to-age
      statix
      strace
      supermin
      syslinux
      tealdeer
      thunderbird
      traceroute
      tradingview
      transfer-sh
      tree
      luaPackages.tree-sitter-cli
      trivy
      vector
      velero
      vesktop
      vlc
      worktrunk
      yara
      yay
      yazi
      yq-go
      yt-dlp
      zoom-us
      zsh-powerlevel10k
      zstd
    ];

    file = {
      ".kube/kubie.yaml".source = ./config/kubie.yaml;
      ".ssh/config".source = ./config/ssh/config;
    };

    activation = {
      ensureKubeconfigDirectory = lib.hm.dag.entryBetween [ "sops-nix" ] [ "writeBoundary" ] ''
        # Also correct permissions on existing installs before SOPS creates links.
        run ${pkgs.coreutils}/bin/install -d -m 0700 ${lib.escapeShellArg "${config.home.homeDirectory}/.kube/kubeconfig"}
      '';
    };
  };

  nixpkgs.config.allowUnfree = true;
}
