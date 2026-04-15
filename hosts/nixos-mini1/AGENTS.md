# AGENT – nixos-mini1 host

`hosts/nixos-mini1` defines the worker NixOS mini host in this repo. The host targets NixOS `25.11`, uses a static IPv4 address on `enp6s0`, installs the `gabriel` admin user with your SSH key, and now relies on `disko` plus `nixos-facter` to provision disks and hardware metadata.

Goals:

- Keep the host bootstrap light while planning for future services (Syncthing, observability stack, etc.).
- Future updates should import shared modules from `modules/` once they exist so common logic is not duplicated.
- Document the k0s worker join flow so reviewers know how the token is supplied and which ports are exposed to the LAN.

Workflow reminders:

- Do not run `nixos-rebuild` or edit this configuration without confirmation; coordinate the command with whoever verifies the resulting system before deployment.
- `disk-config.nix` describes how `disko` should partition the 500G disk for `/boot` + `/` and the 1T disk for `/data`. Pass `--disk-config hosts/nixos-mini1/disk-config.nix` to `nixos-anywhere` so the installer uses this layout.
- The install command now also generates `hosts/nixos-mini1/facter.json` with `--generate-hardware-config nixos-facter hosts/nixos-mini1/facter.json`. The flake imports that report via `hardware.facter.reportPath`.
- `services.k0s` is enabled as a worker; the join token must be encrypted at `secrets/k0s/token-mini1.yaml` and is deployed via `sops-nix` to `/etc/k0s/k0stoken` (root:root, 0400). The firewall exposes worker/overlay ports `10250`, `4240`, `4244` (TCP) and `8472`, `6081` (UDP).
