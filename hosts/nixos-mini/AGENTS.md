# AGENT – nixos-mini host

`hosts/nixos-mini` defines the single NixOS host in this repo. The host targets NixOS `25.11`, uses a static IPv4 address on `enp6s0`, installs the `gabriel` admin user with your SSH key, and now relies on `disko` plus `nixos-facter` to provision disks and hardware metadata.

Goals:

- Keep the host bootstrap light while planning for future services (Syncthing, observability stack, etc.).
- Future updates should import shared modules from `modules/` once they exist so common logic is not duplicated.
- Document the k0s controller+worker stack so reviewers know how the join token is supplied and which ports are exposed to the LAN.

Workflow reminders:

- Do not run `nixos-rebuild` or edit this configuration without confirmation; coordinate the command with whoever verifies the resulting system before deployment.
- `disk-config.nix` describes how `disko` should partition `/dev/sdb` for `/boot` + `/` and `/dev/sda` for `/data`. Pass `--disk-config hosts/nixos-mini/disk-config.nix` to `nixos-anywhere` so the installer uses this layout.
- The install command now also generates `hosts/nixos-mini/facter.json` with `--generate-hardware-config nixos-facter hosts/nixos-mini/facter.json`. The flake imports that report via `hardware.facter.reportPath`.
- `services.k0s` is enabled as a controller+worker; the join token must be encrypted at `secrets/k0s/k0stoken.yaml` and is deployed via `sops-nix` to `/etc/k0s/k0stoken` (root:root, 0400). The firewall now programs iptables rules to allow 6443, 8132, 10250, and 8472 only from `192.168.0.0/24`.
