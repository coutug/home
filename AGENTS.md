# AGENT – Nix configurations (workstation & servers)

**Language policy:** keep this file in English. Do not translate it, even if requests are made in French.

This repo hosts Home Manager configurations (EndeavourOS) and prepares future NixOS hosts. Every change must stay declarative and reproducible via the root flake.

---

## Snapshot (Jan 2026)
- Flake (`flake.nix`)
  - `nixpkgs` : `nixos-unstable` (voir `flake.lock`).
  - `home-manager` : `master` (voir `flake.lock`).
  - `nixgl` suit `nixpkgs`, utilisé via `nixgl.overlay`/`config.lib.nixGL.wrap`.
  - `sops-nix` suit `nixpkgs` (commit `c482a1…`).
  - `opencode` : flake officiel `anomalyco/opencode` épinglé sur `v1.1.31` (voir `flake.nix`/`flake.lock`).
- `flake.lock` est à jour (mis à jour le 27 nov 2025), garder ce rythme à chaque changement de channel.
- Workspace arrangé pour `system = "x86_64-linux"`, `config.allowUnfree = true`, plus overlay nixGL.

## Layout & conventions
- `home/`
  - `common.nix` : socle pour l’utilisateur `gabriel`. Configure `targets.genericLinux`, `sops-nix`, exports secrets kubeconfig, variables d’environnement, packages, `xdg.configFile`, et désactive les sorties `manual` HM (évite l’avertissement « options.json sans contexte » sur HM 25.11).
  - `laptop.nix` / `desktop.nix` : importent `common.nix`; le desktop ajoute les paquets `reaper*`.
  - `server.nix` : squelette (utilisateur `myuser`, `stateVersion = 23.11`) injecté côté NixOS.
  - `programs/*.nix` : modules isolés (atuin, bat, fzf, htop, k9s, obs-studio, wezterm, zoxide, zsh). `wezterm` et `obs-studio` sont encapsulés avec `nixGL`.
  - `home/common.nix` : `opencode` provient désormais du flake officiel (pas de `pkgs.opencode`).
  - `config/` & `dotfiles/` : sources VS Code, tmux, oh-my-zsh custom, etc., montés via `home.file`/`xdg.configFile`.
  - `config/codex/` : (supprimé) — la configuration Codex est désormais uniquement sous `secrets/codex/config.toml` (sops) et déployée vers `~/.codex/config.toml` via sops-nix, seulement si le fichier existe (test `pathExists`).
  - `config/opencode/opencode.json` : configuration OpenCode déclarative (plugin OAuth + modèles), déployée vers `~/.config/opencode/opencode.json` via `xdg.configFile`.
  - `config/ssh/`: tracks `config/ssh/config` and exposes it through `home.common.nix` so `~/.ssh/config` stays declarative.
- `hosts/`
  - `nixos-mini/`: base `configuration.nix` + minimal `hardware-configuration.nix`; only real value `stateVersion = "23.11"`.
- `modules/`: empty for now. Planned for future shared NixOS modules.
- `secrets/`
  - `kubeconfig/*.yml` revealed via `home/common.nix` into `~/.kube/kubeconfig/<name>.yml` (via sops-nix).
  - `codex/config.toml`: encrypted version containing the real `INCIDENT_IO_API_KEY`. Exposed to `~/.codex/config.toml` via sops-nix. No cleartext file kept in the repo.

## Workflow
- Update inputs: `nix flake update` (watch warnings with a dirty Git tree).
- Apply user config: `home-manager switch --flake .#laptop` (or `.#desktop`).
- Prepare a NixOS machine: `nixos-rebuild build --flake .#nixos-mini` (then `--target-host` when modules exist).
- Known warnings resolutions
  - `builtins.toFile options.json`: fixed by disabling `manual.{html,json,manpages}` in `home/common.nix`.
  - `pkgs.system` deprecated: replaced with `pkgs.stdenv.hostPlatform.system` for `nixGL` (line 13 of `home/common.nix`).
  - “download buffer is full”: set `download-buffer-size` in `/etc/nix/nix.custom.conf` (e.g., `134217728` for 128 MiB) via Determinate.

## Next steps (servers)
1. **Real user**: replace `home/server.nix` (`myuser`) with the target user and factor a shared module (`home/server/common.nix`).
2. **Common NixOS module**: populate `modules/server/base.nix` (SSH, firewall, journald, nix settings, sops-nix, download buffer, Determinate substituters).
3. **nixos-mini**: enrich `hosts/nixos-mini/configuration.nix` with the common module + basic services (Syncthing? Node exporter?).
4. **Secrets**: document how to distribute age keys on servers and validate rotation.
5. **Observability stack**: plan Grafana/VictoriaMetrics/Vector + k0s, internal DNS, Vaultwarden, Syncthing; define which services live on which nodes.

## Open questions
- Which OS/base version for new servers (stay on 23.11 or move to 25.05/25.11)?
- SSH access policy (key, port, root login, MFA) still to define.
- Need a shared `nix.settings` module to centralize `download-buffer-size`, `extra-substituters`, etc.?
- Storage/backup layout (ZFS, RAID, restic, borg?).

## Operational reminders
- Always run `nix flake check` before pushing or deploying.
- Manage secrets via `sops --encrypt --age <pubkey> …` then add to `secrets/`. Let `home/common.nix` handle provisioning.
- Keep `README.md` aligned with reality (channels, modules). Any new dependency must flow through `flake.lock`.
- Document in this file any new operational rule (new module, secrets policy, deployment procedure) as soon as it’s decided.
- **Golden rule:** any change to configuration (Home Manager, NixOS hosts, secrets, workflows) must be reflected here before the task is considered done.
