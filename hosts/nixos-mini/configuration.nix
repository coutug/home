{
  pkgs,
  lib,
  k0s-nix,
  sops-nix,
  ...
}:

let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEr2BKqV1JZ1SHtkjEsRCFD6UbXVIsZ4NfB27G/CW2Km gabriel@framework-gabriel";
  k0sTokenSecret = ../secrets/k0s/k0stoken.yaml;
  hasK0sTokenSecret = lib.pathExists k0sTokenSecret;
in
{
  imports = [
    ./disk-config.nix
    sops-nix.nixosModules.sops
  ];

  networking.hostName = "nixos-mini";
  networking.useDHCP = false;
  networking.enableIPv6 = false;
  networking.interfaces.enp6s0 = {
    ipv4.addresses = [
      {
        address = "192.168.0.14";
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
      6443
      8132
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

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
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

  services.k0s = {
    enable = true;
    role = "controller+worker";
    controller.isLeader = true;
    clusterName = "k0s-mini";
    # tokenFile = "/etc/k0s/k0stoken";
    dataDir = "/var/lib/k0s";
    package = k0s-nix.packages.${pkgs.stdenv.hostPlatform.system}.k0s;
    configText = builtins.readFile ./k0s-config.yaml;
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
    fio
    ripgrep
    vim
  ];

  sops.secrets = lib.mkIf hasK0sTokenSecret {
    "k0s/k0stoken" = {
      sopsFile = k0sTokenSecret;
      format = "yaml";
      path = "/etc/k0s/k0stoken";
      mode = "0400";
      owner = "root";
      group = "root";
    };
  };

}
