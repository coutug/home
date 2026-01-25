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
    ./programs/zsh.nix
  ];

  home.username = "gabriel";
  home.homeDirectory = "/home/gabriel";
  home.stateVersion = "25.11";

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
}
