# Nix home & host configurations

This repository keeps the declarative state for the EndeavourOS personal machines under `home/` along with the NixOS host definitions under `hosts/`. The root `flake.nix` wires everything, and you can consult `AGENTS.md` files for detailed guidelines about each domain.

## Workspace layout
- `home/`: Home Manager configuration for `gabriel`. `common.nix` defines shared packages, programs, and secrets. `laptop.nix`/`desktop.nix` lift the shared profile into the per-machine goals, while `home/programs`, `home/config`, and `home/dotfiles` expose smaller helpers and static files.
- `hosts/`: NixOS host configurations. `nixos-mini` is the only machine today, targets NixOS `25.11`, and anchors the `modules/` directory for future hosts.
- `modules/`: currently empty. Intended to hold reusable NixOS modules (SSH, firewall, journald, nix settings, etc.).
- `secrets/`: SOPS-encrypted data (Codex, OpenCode, kubeconfigs). `home/common.nix` and eventual NixOS configs unwrap the secrets into the home directory.
- `result/`: build artifact from the last Home Manager switch. Do not edit; treat it as unleveled output.

## Key workflows
- **Inputs:** run `nix flake update`, `nix flake show`, and `nix flake check` to refresh or validate the flake inputs. These operations do not change the managed machines.
- **Home Manager:** the `home/` directory drives `home-manager switch --flake .#laptop` (or `.#desktop`). Please ask before running any `home-manager` command, especially those that switch or build profiles.
- **NixOS hosts:** `hosts/` contents are built with `nixos-rebuild` (or similar commands). Always confirm before invoking `nixos-rebuild` on any host or target machine.
- **Install helper:** We retain `hosts/nixos-mini/disk-config.nix` plus the generated `hosts/nixos-mini/facter.json` so `nixos-anywhere` can partition `/dev/sdb` for `/boot`+`/` and `/dev/sda` for `/data`. Use the command below once everything else is reviewed:
  `nix run github:nix-community/nixos-anywhere -- --flake .#nixos-mini --target-host gabriel@192.168.0.14 --disk-config hosts/nixos-mini/disk-config.nix --generate-hardware-config nixos-facter hosts/nixos-mini/facter.json`

## Directory guides
Each major folder defines its own `AGENTS.md` that explains its intent, conventions, and the current status. Read the relevant `AGENTS.md` before editing a section of the tree, especially if you plan to change how secrets are handled, add packages, or alter host state.

- `AGENTS.md` (root): workspace goals, flake snapshot, and operational reminders.
- `home/AGENTS.md`: description of the Home Manager configuration, general structure, and how to add new modules.
- `home/programs/AGENTS.md`: guidance for the per-program modules imported into `common.nix` (keep them small and reusable).
- `hosts/AGENTS.md`: explanation of the NixOS host layout and how to add new hosts or modules.
- `hosts/nixos-mini/AGENTS.md`: specific notes about the current `nixos-mini` system.
- `modules/AGENTS.md`: placeholder for documenting shared module fixtures when they arrive.
- `secrets/AGENTS.md`: how encrypted secrets are stored, exposed, and added to the tree.

## Installation reminders
- Follow the Determinate Nix installer instructions without deviating from the documented settings (e.g., leave `download-buffer-size` and substituters as expected and keep `config.allowUnfree = true`).
- After installation, always read `home/AGENTS.md` before running any `home-manager` commands so you understand the imports, programs, and file deployments.

## Documentation housekeeping
Any new operational rule (new module, dependency, workflow, or secret policy) must be recorded in the relevant `AGENTS.md`. Updating those files is part of the change itself.
