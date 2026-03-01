# AGENT – nixos-mini1 host

`hosts/nixos-mini1` defines the primary NixOS mini host in this repo. The host targets NixOS `25.11`, uses a static IPv4 address on `enp6s0`, installs the `gabriel` admin user with your SSH key, and now relies on `disko` plus `nixos-facter` to provision disks and hardware metadata.

Goals:

- Keep the host bootstrap light while planning for future services (Syncthing, observability stack, etc.).
- Future updates should import shared modules from `modules/` once they exist so common logic is not duplicated.
- Document the k0s controller+worker stack so reviewers know how the join token is supplied and which ports are exposed to the LAN.

Workflow reminders:

- Do not run `nixos-rebuild` or edit this configuration without confirmation; coordinate the command with whoever verifies the resulting system before deployment.
- `disk-config.nix` describes how `disko` should partition `/dev/sdb` for `/boot` + `/` and `/dev/sda` for `/data`. Pass `--disk-config hosts/nixos-mini1/disk-config.nix` to `nixos-anywhere` so the installer uses this layout.
- The install command now also generates `hosts/nixos-mini1/facter.json` with `--generate-hardware-config nixos-facter hosts/nixos-mini1/facter.json`. The flake imports that report via `hardware.facter.reportPath`.
- `services.k0s` is enabled as a controller+worker; the join token must be encrypted at `secrets/k0s/k0stoken.yaml` and is deployed via `sops-nix` to `/etc/k0s/k0stoken` (root:root, 0400). The firewall exposes controller ports `6443`, `8132`, `9443`, `2379`, `2380`, plus worker/overlay ports `10250`, `4240`, `4244` (TCP) and `8472`, `6081` (UDP).
