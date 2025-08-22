{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  home.packages = with pkgs; [
    reaper
    reaper-sws-extension
    reaper-reapack-extension
  ];

}
