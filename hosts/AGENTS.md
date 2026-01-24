# AGENT – NixOS hosts

The `hosts/` directory contains the NixOS configuration for every machine managed from this repository. Each subdirectory corresponds to a host (for now only `nixos-mini`), with its own `configuration.nix` and `hardware-configuration.nix`.

Structure:

- `hosts/nixos-mini`: minimal base system with the current `stateVersion = "23.11"`. It imports the hardware configuration and sets the hostname to `nixos-mini`.
- `modules/`: intended to hold shared NixOS modules that hosts can import (firewall, SSH, journald, nix settings, etc.).

Workflow reminders:

- `hosts/` is the only place where you would run `nixos-rebuild` or similar commands. Please ask for confirmation before invoking any NixOS build or deployment from this directory.
- Keep host directories declarative and reproducible through the flake; avoid side effects.
