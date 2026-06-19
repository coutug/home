# AGENT – Nix configurations

**Language policy:** keep this file in English.

This repo manages Home Manager profiles, NixOS host configurations, and SOPS-encrypted secrets through the root `flake.nix`.

## Baseline
- `nixpkgs`: `nixos-25.11`
- `home-manager`: `release-25.11`
- `nixgl`, `sops-nix`, and `opencode` are pinned in `flake.lock`
- target system: `x86_64-linux`
- `allowUnfree = true`

## Repository map
- `home/`: Home Manager profiles and reusable program modules
- `hosts/`: NixOS host configurations
- `secrets/`: SOPS-encrypted data consumed by the configs
- `modules/`: shared NixOS modules, when present

## Global rules
- Keep all changes declarative and reproducible through the flake.
- Do not run deployment commands (`home-manager switch`, `nixos-rebuild`, `nixos-anywhere`) without explicit approval.
- Never commit plaintext secrets; use SOPS.
- Run `nix flake check` before push or deployment.
- If structure or operational rules change, update the relevant `AGENTS.md`.
