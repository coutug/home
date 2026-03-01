# AGENT – NixOS hosts

The `hosts/` directory contains the NixOS configuration for every machine managed from this repository. Each subdirectory corresponds to a host (`nixos-mini1`, `nixos-mini2`), with its own `configuration.nix` and the `facter.json` report generated via `nixos-facter`.

Structure:

- `hosts/nixos-mini1`: minimal base system with the current `stateVersion = "25.11"`. It imports the disk layout (`disk-config.nix`), enables the `disko` module, and references the `facter.json` report so `nixos-anywhere` can build the host with the right drivers.
- `hosts/nixos-mini1`: primary k0s controller+worker powered by the `johbo/k0s-nix` flake.
- `hosts/nixos-mini2`: secondary host that joins the same `k0s-mini` cluster as a controller+worker and consumes the join token stored in `secrets/k0s/token-mini2.yaml`. It keeps `hardware.facter.reportPath` enabled and sanitizes null CPU entries from the report to avoid the `hardware/facter/virtualisation.nix` evaluation failure.
- `modules/`: intended to hold shared NixOS modules that hosts can import (firewall, SSH, journald, nix settings, etc.).

Workflow reminders:

- `hosts/` is the only place where you would run `nixos-rebuild` or similar commands. Please ask for confirmation before invoking any NixOS build or deployment from this directory.
- Keep host directories declarative and reproducible through the flake; avoid side effects.
