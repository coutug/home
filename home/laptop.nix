{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  home.username = "myuser";
  home.homeDirectory = "/home/myuser";
  home.stateVersion = "23.11";
}
