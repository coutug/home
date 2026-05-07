{
  config,
  lib,
  ...
}:

let
  cfg = config.mini.sopsBootstrap;
  usersSecret = ../../secrets/users/mini.yaml;
  hasUsersSecret = lib.pathExists usersSecret;
in
{
  options.mini.sopsBootstrap = {
    enablePasswordSecrets = lib.mkEnableOption "SOPS-managed root and gabriel password hashes";
  };

  config = {
    services.openssh.hostKeys = lib.mkForce [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    systemd.tmpfiles.rules = [
      "z /etc/ssh/ssh_host_ed25519_key 0600 root root - -"
      "z /etc/ssh/ssh_host_ed25519_key.pub 0644 root root - -"
    ];

    sops.secrets = lib.mkIf (cfg.enablePasswordSecrets && hasUsersSecret) {
      "users/root-password-hash" = {
        sopsFile = usersSecret;
        key = "root-password-hash";
        neededForUsers = true;
      };

      "users/gabriel-password-hash" = {
        sopsFile = usersSecret;
        key = "gabriel-password-hash";
        neededForUsers = true;
      };
    };

    users.users.root.hashedPasswordFile = lib.mkIf (
      cfg.enablePasswordSecrets && hasUsersSecret
    ) config.sops.secrets."users/root-password-hash".path;

    users.users.gabriel.hashedPasswordFile = lib.mkIf (
      cfg.enablePasswordSecrets && hasUsersSecret
    ) config.sops.secrets."users/gabriel-password-hash".path;
  };
}
