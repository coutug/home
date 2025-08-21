{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./programs/k9s.nix
  ];

  home.username = "gabriel";
  home.homeDirectory = "/home/gabriel";
  home.stateVersion = "25.05";

  programs = {
    alacritty.enable = true;
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
    # zsh.enable = true;
  };

  home.packages = with pkgs; [
    act
    age
    argocd
    # bluez
    # bluez-tools
    crane
    curlie
    # discount
    duf
    etcd
    # fd #TODO dependency
    fluxcd
    # fwupd
    # fwupd-efi
    github-cli
    go-jsonnet
    helmfile
    home-manager
    hey
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
    kubernetes-helm
    kustomize
    krew
    k0sctl
    lazydocker
    lazygit
    # libguestfs
    minikube
    musescore
    nix-zsh-completions
    nmap
    obs-studio
    qbittorrent-enhanced
    rclone
    rsync
    # ripgrep #TODO dependency
    solaar
    sops
    spotify
    tealdeer
    traceroute
    tree
    opentofu
    trivy
    vector
    velero
    vesktop
    vlc
    yay
    yazi
    yq-go
    zoom-us
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "spotify"
      "zoom"
    ];
  

  home.file.".tmux.conf" = {
    source = ./config/tmux.conf;
  };

  xdg.configFile."tmuxinator/kmux.yml" = {
    source = ./config/kmux.yml;
  };

  # fonts.fontconfig.enable = true;
}
