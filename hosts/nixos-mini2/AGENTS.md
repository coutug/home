# AGENT – nixos-mini2 host

`hosts/nixos-mini2` defines the primary NixOS mini host in this repo. The host targets NixOS `25.11`, uses a static IPv4 address on `enp4s0`, installs the `gabriel` admin user with your SSH key, and now relies on `disko` plus `nixos-facter` to provision disks and hardware metadata.

Goals:

- Keep the host bootstrap light while planning for future services (Syncthing, observability stack, etc.).
- Future updates should import shared modules from `modules/` once they exist so common logic is not duplicated.
- Document the k0s controller bootstrap so reviewers know how the cluster starts and which ports are exposed to the LAN.

Workflow reminders:

- Do not run `nixos-rebuild` or edit this configuration without confirmation; coordinate the command with whoever verifies the resulting system before deployment.
- `disk-config.nix` describes how `disko` should partition the 4T disk for `/boot` + `/` and the 2T disk for `/data`. Pass `--disk-config hosts/nixos-mini2/disk-config.nix` to `nixos-anywhere` so the installer uses this layout.
- The install command now also generates `hosts/nixos-mini2/facter.json` with `--generate-hardware-config nixos-facter hosts/nixos-mini2/facter.json`. This host keeps facter enabled and sanitizes the imported report by filtering null CPU entries before the module evaluation stage.
- `services.k0s` is enabled as the controller+worker bootstrap node for the `k0s-mini` cluster. The firewall exposes controller ports `6443`, `8132`, `9443`, `2379`, `2380`, plus worker/overlay ports `10250`, `4240`, `4244` (TCP) and `8472`, `6081` (UDP).
