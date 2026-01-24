{
  config,
  pkgs,
  lib,
  ...
}:

let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEr2BKqV1JZ1SHtkjEsRCFD6UbXVIsZ4NfB27G/CW2Km gabriel@framework-gabriel";
in
{
  imports = [
    ./disk-config.nix
  ];

  networking.hostName = "nixos-mini";
  networking.interfaces.enp6s0.ipv4.addresses = [
    {
      address = "192.168.0.14";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.0.1";
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "8.8.8.8"
  ];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
  };

  programs.zsh = {
    enable = true;
  };

  users.users.gabriel = {
    isNormalUser = true;
    description = "Primary administrator";
    home = "/home/gabriel";
    createHome = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ sshKey ];
  };

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    download-buffer-size = 134217728;
  };

  environment.systemPackages = with pkgs; [
    duf
    htop
    git
    disko
  ];

}
