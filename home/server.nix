{ pkgs, ... }:
{
  home.username = "gabriel";
  home.homeDirectory = "/home/gabriel";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [ vim ];
}
