{ config, pkgs, system, nixgl, ... }:
{
  targets.genericLinux.enable = true;

  nixGL = {
    packages = nixgl.packages.${pkgs.system}; # you must set this or everything will be a noop
    defaultWrapper = "mesa"; # choose from options
  };

  imports = [
    ./programs/k9s.nix
    ./programs/zsh.nix
    ./programs/wezterm.nix
  ];

  home.username = "gabriel";
  home.homeDirectory = "/home/gabriel";
  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    WINEFSYNC=1;  # Optimize vst performance
    BUN_INSTALL="${config.home.homeDirectory}/.bun";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.bun/bin"
  ];
  programs = {
    # Let Home Manager install and manage itself
    home-manager.enable = true;

    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = { auto_sync = true; };
    };
    bat.enable = true;
    fzf = {
      enable = true; #TODO dependency
      enableZshIntegration = true;
    };
    # git.enable = true;
    htop.enable = true;
    # neovim.enable = true;
    # tmux.enable = true;
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home.packages = with pkgs; [
    # nixgl.nixGLIntel

    augeas
    act
    age
    argocd
    # bluez
    # bluez-tools
    crane
    curlie
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
    nmap
    obs-studio
    poppler
    qbittorrent-enhanced
    resvg
    rclone
    rsync
    # ripgrep #TODO dependency
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
    opentofu
    trivy
    vector
    velero
    vesktop
    vim
    vlc
    yara
    yay
    yazi
    yq-go
    zellij
    zoom-us
    zsh-powerlevel10k
  ];
  
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "reaper"
      "spotify"
      "zoom"
    ];
  

  # ~/
  home.file = {
    ".tmux.conf".source = ./config/tmux.conf;
  };
  # ~/.config
  xdg.configFile = {
    "Code/User/settings.json".source = ./config/code/user/settings.json;
    "tmuxinator/kmux.yml".source = ./config/kmux.yml;
  };

  # fonts.fontconfig.enable = true;
}