{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  home.username = "gabriel";
  home.homeDirectory = "/home/gabriel";
  home.stateVersion = "25.05";

  programs = {
    alacritty.enable = true;
    bat.enable = true;
    # fzf.enable = true; #TODO dependency
    # git.enable = true;
    htop.enable = true;
    # k9s.enable = true;
    # neovim.enable = true;
    # tmux.enable = true;
    zoxide.enable = true;
    # zsh.enable = true;
  };

  home.packages = with pkgs; [
    act
    age
    argocd
    crane
    curlie
    duf
    # fd #TODO dependency
    fluxcd
    github-cli
    helm
    helmfile
    home-manager
    # jq #TODO dependency
    # kubectl #TODO dependency
    kustomize
    lazydocker
    lazygit
    nmap
    rclone
    # ripgrep #TODO dependency
    sops
    tealdeer
    opentofu
    trivy
    yq-go
  ];

  home.file.".tmux-nix.conf" = {
    source = ./config/.tmux.conf;
  };

  # fonts.fontconfig.enable = true;
}
