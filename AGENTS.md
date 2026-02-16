# AGENT – Nix configurations (workstation & servers)

**Language policy:** keep this file in English. Do not translate it, even if requests are made in French.

This repo stores the Home Manager configurations for the EndeavourOS workstations and prepares NixOS hosts. Every change must remain declarative and reproducible through the root `flake.nix`.

## Snapshot (Jan 2026)
- Flake (`flake.nix`)
  - `nixpkgs`: `nixos-25.11` (see `flake.lock`).
  - `home-manager`: `release-25.11` (see `flake.lock`).
  - `nixgl`: follows `nixpkgs`, used through `nixgl.overlay` and `config.lib.nixGL.wrap`.
  - `sops-nix`: follows `nixpkgs` (commit `c482a1…`).
  - `opencode`: official `anomalyco/opencode` flake pinned to `v1.1.31` (see `flake.nix`/`flake.lock`).
- `flake.lock` is up to date (updated Jan 24 2026); keep the same cadence whenever channels change.
- Workspace assumes `system = "x86_64-linux"`, `config.allowUnfree = true`, and the nixGL overlay.
- `home/common.nix` now mirrors the flake-level `nixpkgs.config.allowUnfree = true` so the home profile can build unfree packages like `antigravity`.

## Layout & conventions
- `home/`
  - `common.nix`: base profile for user `gabriel`. It configures `targets.genericLinux`, `sops-nix`, exports the kubeconfig secrets, sets session variables, packages, `xdg.configFile`, and disables the manual outputs that trigger the HM 25.11 warning about `options.json` with no context.
  - `laptop.nix` / `desktop.nix`: import `common.nix`; the desktop adds the `reaper*` packages.
  - `home/config/wezterm/cyberdream.lua`: stores the official cyberdream theme and is deployed into `~/.config/wezterm/cyberdream.lua` via the `xdg.configFile` entry and `extraConfig` in `home/programs/wezterm.nix`.
- `server.nix`: skeleton for the host-side home profile used by NixOS; it now defines user `gabriel` with `stateVersion = "25.11"`, selectively imports `./programs/zsh.nix`, and wires in `sops-nix` so `nixos-mini` reuses the shared Zsh setup without pulling the entire `common.nix` surface or all secrets. It now flips a session flag so the Powerlevel10k arrow and path segment turn orange in server shells, keeping the rest of the prompt identical.
  - `programs/*.nix`: modular definitions for tools like `atuin`, `bat`, `fzf`, `htop`, `k9s`, `obs-studio`, `wezterm`, `zoxide`, and shell tooling. `wezterm` and `obs-studio` are wrapped with `nixGL`.
  - `config/` & `dotfiles/`: static VS Code settings, tmux, Oh My Zsh custom assets, etc., exposed via `home.file`/`xdg.configFile`.
  - `config/opencode/opencode.json`: declarative OpenCode configuration (OAuth plugin + templates), placed under `~/.config/opencode/opencode.json`.
  - `config/ssh/`: tracks `config/ssh/config` and exposes it through `home.common.nix` so `~/.ssh/config` remains declarative.
- `hosts/`
  - `nixos-mini/`: NixOS 25.11 host with static IPv4 on `enp6s0`, systemd-boot, and a disk layout described in `disk-config.nix` for `disko`. `nixos-anywhere` now generates `hosts/nixos-mini/facter.json` via `nixos-facter` instead of `hardware-configuration.nix`.
- `modules/`: currently empty. Intended for shared NixOS modules (firewall, SSH, journald, nix settings, etc.).
- `secrets/`
- `kubeconfig/*.yml`: exposed by `home/common.nix` under `~/.kube/kubeconfig/<name>.yml` via `sops-nix`.
- `codex/config.toml`: encrypted file with the real `INCIDENT_IO_API_KEY`, exposed as `~/.codex/config.toml`.
- `k0s/k0stoken.yaml`: new SOPS secret that maps to `/etc/k0s/k0stoken` (owner `root`, mode `0400`) so the controller+worker can start with the cluster join token.

## Workflow
- Update inputs: `nix flake update` (warnings may appear when the tree is dirty).
- Apply the workstation profile: `home-manager switch --flake .#laptop` (or `.#desktop`).
- Prepare the NixOS host: run the `nixos-anywhere` command from this repo with `hosts/nixos-mini/disk-config.nix` and generate `hosts/nixos-mini/facter.json` via `--generate-hardware-config nixos-facter hosts/nixos-mini/facter.json` before running or rebuilding the system.
- Known warning solutions:
  - `builtins.toFile options.json`: solved by disabling `manual.{html,json,manpages}` in `home/common.nix`.
  - Deprecated `pkgs.system`: replaced with `pkgs.stdenv.hostPlatform.system` for nixGL (see `home/common.nix`).
  - "download buffer is full": adjust `download-buffer-size` in `/etc/nix/nix.custom.conf` (e.g., `134217728`) via the Determinate installer.

## Next steps (servers)
1. **Real user**: keep `home/server.nix` aligned with the host profile and confirm `gabriel` is the user that needs provisioning.
2. **Common NixOS module**: populate `modules/server/base.nix` with shared pieces (SSH policy, firewall rules, journald tweaks, nix settings, sops-nix, download buffer, Determinate substituters).
3. **nixos-mini**: wire the host into the common module, expose metrics (Syncthing, node exporter, etc.), and keep `disk-config.nix` in sync with any future partitions.
4. **Secrets**: document how to propagate age keys to hosts and validate rotation policies.
5. **Observability & services**: `nixos-mini` now runs a `k0s` controller+worker alongside Syncthing, Grafana, VictoriaMetrics, Vector, DNS, and Vaultwarden; keep this stack documented, expose secrets through `sops-nix`, and keep `disk-config.nix`/hardware assets in sync.
6. **nixos-mini Zsh**: keep `home/server.nix` minimal so it only imports `home/programs/zsh.nix`, letting the host reuse the shared Zsh + dotfile stack without pulling the entire `home/common.nix` surface.

## Open questions
- Which additional services should `nixos-mini` host (monitoring, backup targets, etc.)?
- What is the best SSH access policy (keys, port, root login, MFA) across all hosts?
- Do we want a shared `nix.settings` module to centralize `download-buffer-size`, `extra-substituters`, garbage collection, etc.?
- How should data and backups be organized (ZFS, RAID, restic, borg, off-server storage)?

## Operational reminders
- Always run `nix flake check` before pushing or deploying.
- Manage secrets via `sops --encrypt --age <pubkey> …` before adding them to `secrets/`. Let `home/common.nix` (or the host config) handle provisioning.
- Keep `README.md` aligned with reality (channels, modules). Any new dependency must flow through `flake.lock`.
- Document new operational rules (modules, secrets policy, deployment steps) in this file as they are decided.
- **Golden rule:** any change to configuration (Home Manager, NixOS hosts, secrets, workflows) must be reflected here before the task is considered done.
