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
    # zsh.enable = true;
    zoxide.enable = true;
  };

  home.packages = with pkgs; [
    duf
    home-manager
    # fd #TODO dependency
    # ripgrep #TODO dependency
    tealdeer
    lazygit
    lazydocker
    curlie
    # jq #TODO dependency
    github-cli
    kubectl
    # kustomize helm helmfile argocd fluxcd
    # sops age yq-go trivy terraform rclone
    # act crane nmap
  ];

}
