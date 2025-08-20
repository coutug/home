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
    bluez
    bluez-tools
    crane
    curlie
    discount
    duf
    # fd #TODO dependency
    fluxcd
    fwupd
    fwupd-efi
    github-cli
    helmfile
    home-manager
    # jq #TODO dependency
    kdePackages.ark
    kdePackages.bluedevil
    kdePackages.okular
    kubectl
    kubelogin-oidc
    kubernetes-helm
    kustomize
    krew
    lazydocker
    lazygit
    nmap
    rclone
    # ripgrep #TODO dependency
    sops
    tealdeer
    opentofu
    trivy
    velero
    yq-go
  ];

  home.file.".tmux.conf" = {
    source = ./config/tmux.conf;
  };

  xdg.configFile."tmuxinator/kmux.yml" = {
    source = ./config/kmux.yml;
  };

  # fonts.fontconfig.enable = true;
}
