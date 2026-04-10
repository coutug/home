{ pkgs, ... }:
{
  imports = [
    ./common.nix
  ];

  # audio device not working, installed with yay
  # home.packages = with pkgs; [
  #   reaper
  #   reaper-sws-extension
  #   reaper-reapack-extension
  # ];

}
