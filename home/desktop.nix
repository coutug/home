{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./programs/zsh.nix
  ];

  home.packages = with pkgs; [
    reaper
    reaper-sws-extension
    reaper-reapack-extension
  ];

}
