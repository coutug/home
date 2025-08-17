{ pkgs, ... }:
let
  nixgl = pkgs.callPackage ../modules/nixGL.nix { };
in
{
  imports = [ ./common.nix ];

  home.username = "gabriel";
  home.homeDirectory = "/home/gabriel";
  home.stateVersion = "25.05";

  # Install nixGL wrapper for OpenGL applications
  home.packages = with pkgs; [
    nixgl.auto.nixGLDefault
  ];

  programs = {
    alacritty = {
      enable = true;
      # package = pkgs.nixgl.auto.nixGLDefault pkgs.alacritty;
    };
  };
}
