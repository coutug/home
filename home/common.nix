{ config, pkgs, ... }:
{
  imports = [ ../modules/nix.nix ];

  home.packages = with pkgs; [
    hello
  ];
}
