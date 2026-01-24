# AGENT – shared NixOS modules

This directory is reserved for reusable NixOS modules that multiple hosts can import. It is empty today (only a `.gitkeep` file exists) but is ready to receive modules for firewall rules, SSH configuration, journald tuning, nix.settings overrides, Determinate substituters, etc.

When adding a module:

- Give it a descriptive name (e.g., `modules/server/base.nix`).
- Document its purpose in this `AGENTS.md` file, keeping the description aligned with the naming convention used elsewhere in this repository.
- Update `hosts/AGENTS.md` (and the relevant host `AGENTS.md`) so reviewers know which hosts consume the module.
