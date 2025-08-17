{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  home.username = "gabriel";
  home.homeDirectory = "/home/gabriel";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    home-manager
  ];

  programs = {
    alacritty = {
      enable = true;
    };
  };
}
