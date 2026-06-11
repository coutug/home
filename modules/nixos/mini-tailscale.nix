{ config, lib, ... }:

let
  cfg = config.mini.tailscale;
in
{
  options.mini.tailscale = {
    enable = lib.mkEnableOption "Tailscale for mini NixOS hosts";

    authKeySopsFile = lib.mkOption {
      type = lib.types.path;
      description = "SOPS-encrypted dotenv file containing the Tailscale auth key as `key`.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.sops.secrets."tailscale/auth-key".path;
      extraUpFlags = [
        "--hostname=${config.networking.hostName}"
      ];
    };

    sops.secrets."tailscale/auth-key" = {
      sopsFile = cfg.authKeySopsFile;
      format = "binary";
      key = "";
      mode = "0400";
      owner = "root";
      group = "root";
    };
  };
}
