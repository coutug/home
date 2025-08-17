{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  home.username = "gabriel";
  home.homeDirectory = "/home/gabriel";
  home.stateVersion = "23.11";

  # Install nixGL wrapper for OpenGL applications
  home.packages = with pkgs; [
    nixgl.auto.nixGLDefault
  ];
}
