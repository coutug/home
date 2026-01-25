{
  config,
  pkgs,
  lib,
  sops-nix,
  k0s-nix,
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
  home.packages = [
    k0s-nix.packages.${pkgs.stdenv.hostPlatform.system}.k0s
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
}
