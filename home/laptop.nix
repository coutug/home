{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  home.username = "myuser";
  home.homeDirectory = "/home/myuser";
  home.stateVersion = "23.11";

  # Install nixGL wrapper for OpenGL applications
  home.packages = with pkgs; [
    nixgl.auto.nixGLDefault
  ];
}
