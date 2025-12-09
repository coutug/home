# AGENT – Configurations Nix (poste & serveurs)

Ce dépôt héberge les configurations Home Manager (EndeavourOS) et prépare les futurs hôtes NixOS. Tout changement doit rester déclaratif et reproductible via le flocon racine.

---

## Snapshot (nov. 2025)
- Flake (`flake.nix`)
  - `nixpkgs` : `nixos-25.11` (commit `a320ce8…`).
  - `home-manager` : `release-25.11` (commit `2217780…`).
  - `nixgl` suit `nixpkgs`, utilisé via `nixgl.overlay`/`config.lib.nixGL.wrap`.
  - `sops-nix` suit `nixpkgs` (commit `c482a1…`).
- `flake.lock` est à jour (mis à jour le 27 nov 2025), garder ce rythme à chaque changement de channel.
- Workspace arrangé pour `system = "x86_64-linux"`, `config.allowUnfree = true`, plus overlay nixGL.

## Layout & conventions
- `home/`
  - `common.nix` : socle pour l’utilisateur `gabriel`. Configure `targets.genericLinux`, `sops-nix`, exports secrets kubeconfig, variables d’environnement, packages, `xdg.configFile`, et désactive les sorties `manual` HM (évite l’avertissement « options.json sans contexte » sur HM 25.11).
  - `laptop.nix` / `desktop.nix` : importent `common.nix`; le desktop ajoute les paquets `reaper*`.
  - `server.nix` : squelette (utilisateur `myuser`, `stateVersion = 23.11`) injecté côté NixOS.
  - `programs/*.nix` : modules isolés (atuin, bat, fzf, htop, k9s, obs-studio, wezterm, zoxide, zsh). `wezterm` et `obs-studio` sont encapsulés avec `nixGL`.
  - `config/` & `dotfiles/` : sources VS Code, tmux, oh-my-zsh custom, etc., montés via `home.file`/`xdg.configFile`.
  - `config/codex/` : (supprimé) — la configuration Codex est désormais uniquement sous `secrets/codex/config.toml` (sops) et déployée vers `~/.codex/config.toml` via sops-nix, seulement si le fichier existe (test `pathExists`).
- `hosts/`
  - `nixos-mini/` : base `configuration.nix` + `hardware-configuration.nix` minimaliste ; seule valeur réelle `stateVersion = "23.11"`.
- `modules/` : vide pour l’instant. Prévu pour futurs modules communs NixOS.
- `secrets/`
  - `kubeconfig/*.yml` révélés via `home/common.nix` dans `~/.kube/kubeconfig/<name>.yml` (via sops-nix).
  - `codex/config.toml` : version chiffrée contenant la vraie `INCIDENT_IO_API_KEY`. Exposé à `~/.codex/config.toml` via sops-nix. Aucun fichier en clair n’est conservé dans le dépôt.

## Flux de travail
- Mise à jour inputs : `nix flake update` (attention aux avertissements dans l’arbre Git sale).
- Appliquer la conf utilisateur : `home-manager switch --flake .#laptop` (ou `.#desktop`).
- Préparer une machine NixOS : `nixos-rebuild build --flake .#nixos-mini` (puis `--target-host` quand les modules existeront).
- Résolution des avertissements connus
  - `builtins.toFile options.json` : résolu en désactivant `manual.{html,json,manpages}` dans `home/common.nix`.
  - `pkgs.system` déprécié : remplacé par `pkgs.stdenv.hostPlatform.system` pour `nixGL` (ligne 13 de `home/common.nix`).
  - « download buffer is full » : définir `download-buffer-size` dans `/etc/nix/nix.custom.conf` (ex. `134217728` pour 128 MiB) via Determinate.

## Prochaines étapes côté serveurs
1. **Utilisateur réel** : remplacer `home/server.nix` (`myuser`) par l’utilisateur cible et factoriser un module partagé (`home/server/common.nix`).
2. **Module NixOS commun** : peupler `modules/server/base.nix` (SSH, firewall, journald, paramètres nix, sops-nix, téléchargement buffer, détermination des substituters locaux).
3. **nixos-mini** : enrichir `hosts/nixos-mini/configuration.nix` avec le module commun + services basiques (Syncthing? Node exporter?).
4. **Secrets** : documenter comment distribuer les clés age sur les serveurs et valider la rotation.
5. **Stack observabilité** : planifier Grafana/VictoriaMetrics/Vector + k0s, DNS interne, Vaultwarden, Syncthing ; définir quels services vivent sur quels nœuds.

## Questions ouvertes
- Quel OS/base version pour les nouveaux serveurs (rester en 23.11 ou migrer vers 25.05/25.11) ?
- Politique d’accès SSH (clé, port, login root, MFA) encore à décrire.
- Besoin d’un module `nix.settings` partagé pour centraliser `download-buffer-size`, `extra-substituters`, etc. ?
- Structure de stockage et de sauvegarde (ZFS, RAID, restic, borg ?).
- Étendue exacte du cluster (nombre de nœuds, sizing CPU/RAM/SSD) pour calibrer les modules.

## Rappels opérationnels
- Toujours lancer `nix flake check` avant de pousser ou déployer.
- Les secrets doivent être gérés via `sops --encrypt --age <pubkey> …` puis ajoutés à `secrets/`. Laisser `home/common.nix` se charger de leur provisioning.
- Pour éviter les surprises, garder `README.md` aligné avec l’état réel (channels, modules). Toute dépendance nouvellement ajoutée doit passer par `flake.lock`.
- Documenter dans ce fichier toute règle opérationnelle supplémentaire (ex. nouveau module, politique de secrets, procédure de déploiement) dès qu’elle est décidée.
- **Règle d’or :** toute modification apportée à la configuration (Home Manager, hôtes NixOS, secrets, workflows) doit être reflétée immédiatement dans `AGENT.md` avant de considérer la tâche terminée.
