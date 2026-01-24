# AGENT – nixos-mini host

`hosts/nixos-mini` defines the single NixOS host in this repo. The host targets NixOS `25.11`, uses a static IPv4 address on `enp6s0`, installs the `gabriel` admin user with your SSH key, and now relies on `disko` plus `nixos-facter` to provision disks and hardware metadata.

Goals:

- Keep the host bootstrap light while planning for future services (Syncthing, observability stack, etc.).
- Future updates should import shared modules from `modules/` once they exist so common logic is not duplicated.

Workflow reminders:

- Do not run `nixos-rebuild` or edit this configuration without confirmation; coordinate the command with whoever verifies the resulting system before deployment.
- `disk-config.nix` describes how `disko` should partition `/dev/sdb` for `/boot` + `/` and `/dev/sda` for `/data`. Pass `--disk-config hosts/nixos-mini/disk-config.nix` to `nixos-anywhere` so the installer uses this layout.
- The install command now also generates `hosts/nixos-mini/facter.json` with `--generate-hardware-config nixos-facter hosts/nixos-mini/facter.json`. The flake imports that report via `hardware.facter.reportPath`.
