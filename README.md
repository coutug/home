# Nix home & host configurations

Declarative Home Manager profiles, NixOS host definitions, and SOPS-encrypted secrets live in this repo and are wired through the root `flake.nix`.

## Layout
- `home/`: Home Manager configuration for `gabriel` (`common.nix`, `laptop.nix`, `desktop.nix`, `server.nix`, `programs/`, `config/`, `dotfiles/`)
- `hosts/`: NixOS hosts (`nixos-mini1`, `nixos-mini2`)
- `secrets/`: encrypted data consumed by the configs
- `modules/`: shared NixOS modules when/if they exist
- `result/`: build output; ignore it

## Workflows
- Refresh/verify inputs with `nix flake update`, `nix flake show`, and `nix flake check`
- Ask before running any `home-manager switch`, `nixos-rebuild`, or `nixos-anywhere` command
- Hosts use `disk-config.nix` plus generated `facter.json` reports for installation

## AGENTS guide
Read the nearest `AGENTS.md` before editing a subtree:
- `AGENTS.md`: repo-wide rules and baseline
- `home/AGENTS.md`: Home Manager conventions
- `hosts/nixos-mini1/AGENTS.md`: worker host specifics
- `hosts/nixos-mini2/AGENTS.md`: primary host specifics
- `secrets/AGENTS.md`: secret handling rules

## Notes
- Keep changes declarative and reproducible.
- Any new operational rule, module, workflow, or secret policy should be reflected in the relevant `AGENTS.md`.
