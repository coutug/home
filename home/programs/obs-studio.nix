{ config, pkgs, ... }:
{
  programs.obs-studio = {
    package = (config.lib.nixGL.wrap pkgs.obs-studio);
    enable = true;
  };
}