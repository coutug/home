{
  pkgs,
  lib,
  k0s-nix,
  ...
}:

let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEr2BKqV1JZ1SHtkjEsRCFD6UbXVIsZ4NfB27G/CW2Km gabriel@framework-gabriel";
in
{
  imports = [
    ./disk-config.nix
  ];

  hardware.enableRedistributableFirmware = true;

  networking.hostName = "nixos-mini3";
  networking.useDHCP = false;
  networking.enableIPv6 = false;
  networking.interfaces.enp4s0 = {
    ipv4.addresses = [
      {
        address = "192.168.0.64";
        prefixLength = 24;
      }
    ];
    useDHCP = false;
  };
  networking.defaultGateway = "192.168.0.1";
  networking.nameservers = [
    "1.1.1.1"
    "192.168.0.1"
  ];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      10250
      4240
      4244
    ];
    allowedUDPPorts = [
      8472
      6081
    ];
    checkReversePath = "loose";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  programs.zsh = {
    enable = true;
  };

  boot.kernelModules = [
    "br_netfilter"
    "overlay"
    "nf_conntrack"
    "ip_tables"
    "iptable_nat"
    "xt_socket"
    "xt_conntrack"
    "ip6_tables"
    "nf_nat"
    "xfrm_user"
    "xfrm_algo"
    "veth"
    "tun"
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
  };

  # k0s is installed now, but the worker join is intentionally deferred.
  # Later, uncomment the SOPS secret and the worker service once the age
  # recipient and token are available.
  # sops-nix.nixosModules.sops
  # secrets/k0s/token-mini3.yaml
  # services.k0s = {
  #   enable = true;
  #   role = "worker";
  #   clusterName = "k0s-mini";
  #   tokenFile = "/etc/k0s/k0stoken";
  #   dataDir = "/var/lib/k0s";
  #   package = k0s-nix.packages.${pkgs.stdenv.hostPlatform.system}.k0s;
  #   configText = builtins.readFile ./k0s-config.yaml;
  # };

  users.users = {
    root.openssh.authorizedKeys.keys = [ sshKey ];
    gabriel = {
      isNormalUser = true;
      description = "Primary administrator";
      home = "/home/gabriel";
      createHome = true;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ sshKey ];
    };
  };

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "gabriel"
    ];
    auto-optimise-store = true;
    download-buffer-size = 134217728;
  };

  environment.systemPackages = with pkgs; [
    duf
    htop
    git
    disko
    fio
    ripgrep
    vim
    k0s-nix.packages.${pkgs.stdenv.hostPlatform.system}.k0s
  ];
}
