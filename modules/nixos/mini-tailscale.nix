{ config, lib, ... }:

let
  cfg = config.mini.tailscale;
  advertiseRoutesFlag = lib.optional (cfg.advertiseRoutes != [ ]) (
    "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"
  );
in
{
  options.mini.tailscale = {
    enable = lib.mkEnableOption "Tailscale for mini NixOS hosts";

    authKeySopsFile = lib.mkOption {
      type = lib.types.path;
      description = "SOPS-encrypted dotenv file containing the Tailscale auth key as `key`.";
    };

    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Subnet routes advertised by this host.";
    };

    useRoutingFeatures = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [
        "none"
        "client"
        "server"
        "both"
      ]);
      default = null;
      description = "Routing feature mode passed to services.tailscale.useRoutingFeatures.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale =
      {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets."tailscale/auth-key".path;
        extraUpFlags = [
          "--hostname=${config.networking.hostName}"
        ] ++ advertiseRoutesFlag;
      }
      // lib.optionalAttrs (cfg.useRoutingFeatures != null) {
        useRoutingFeatures = cfg.useRoutingFeatures;
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
