{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./programs/zsh.nix
  ];

  home.packages = with pkgs; [
    meslo-lgs-nf
    reaper
    reaper-sws-extension
    reaper-reapack-extension
    zsh-powerlevel10k
  ];

}
