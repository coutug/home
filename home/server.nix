{
  config,
  pkgs,
  lib,
  sops-nix,
  ...
}:
{
  imports = [
    sops-nix.homeManagerModules.sops
    ./programs/bat.nix
    ./programs/fzf.nix
    ./programs/home-manager.nix
    ./programs/htop.nix
    ./programs/zsh.nix
    ./programs/zoxide.nix
  ];

  home.username = "gabriel";
  home.homeDirectory = "/home/gabriel";
  home.stateVersion = "25.11";

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
}
