# AGENT – Configurations Nix (poste & serveurs)

Ce dépôt pilote les environnements personnels (laptop, desktop) et prépare désormais une base cohérente pour les serveurs NixOS. Toute contribution doit rester déclarative et réutilisable via les flocons Nix.

---

## Contexte rapide
- Flake racine : `flake.nix` (Nixpkgs 25.05, Home Manager 25.05, nixGL, sops-nix).
- Structures clés : `home/` (profils utilisateur), `hosts/` (machines NixOS), `modules/` (briques réutilisables), `secrets/` (fichiers gérés par sops).
- Secrets actuels : kubeconfig multiples dans `secrets/kubeconfig/*.yml`, exposés par `home/common.nix` vers `~/.kube/kubeconfig/`.
- Commandes usuelles : `nix flake update`, `nix flake check`, `home-manager switch --flake .#<profil>`, `sudo nixos-rebuild switch --flake .#<hôte>`.

## Structure Home Manager
- `home/common.nix` sert de socle partagé : il définit l’utilisateur `gabriel`, configure sops-nix, ajoute les variables d’environnement et importe tous les modules déclarés dans `home/programs/*.nix` (atuin, zsh, wezterm, etc.).
- `home/laptop.nix` ne fait que ré-importer `common.nix`, tandis que `home/desktop.nix` ajoute uniquement les paquets audio `reaper*` par-dessus le socle.
- Les configurations graphiques et CLI supplémentaires se trouvent dans `home/config/` (`Code/User`, `tmuxinator`, `tmux.conf`, etc.) et sont liées via `xdg.configFile`. Les dotfiles dédiés (ex. `home/dotfiles/p10k.zsh`) sont exposés via `home.file`.

## État des machines utilisateur
- **Laptop** (`home/laptop.nix`) : profil complet basé sur `home/common.nix`, tourne sur EndeavourOS via Home Manager.
- **Desktop** (`home/desktop.nix`) : même base que le laptop avec variantes GPU/IA.
- Les deux s’appuient sur l’utilisateur `gabriel` défini dans `home/common.nix`.

## Serveurs NixOS : situation actuelle
- **nixos-mini** (`hosts/nixos-mini/`) : configuration minimale (hostname + `system.stateVersion = "23.11"`). Le flake injecte Home Manager avec `home/server.nix`.
- `home/server.nix` est un squelette (utilisateur `myuser`, aucun module importé).
- `modules/` est vide : à remplir avec des briques spécifiques serveurs (base système, services, monitoring…).
- Objectif global : gérer un petit cluster (k0s, Vaultwarden, Syncthing, DNS interne, Grafana, VictoriaMetrics, Vector, jobs maison).

## Objectifs serveurs (phase 1)
1. **Profil utilisateur serveur** : créer un module Home Manager minimal (zsh, outils CLI nécessaires) sans dépendances graphiques.
2. **Module NixOS commun** : définir `modules/server/base.nix` pour SSH, pare-feu, utilisateur, journald, nix settings, sops-nix.
3. **Hôte de référence** : enrichir `hosts/nixos-mini/configuration.nix` avec le module commun, imports spécifiques (storage, réseau, k0s, services de base).
4. **Gestion des secrets** : décider comment consommer sops-nix côté serveur (clés age, localisation des secrets).
5. **CI légère** : préparer les commandes de build/test (`nix flake check`, `nixos-rebuild --target-host`) pour valider avant déploiement.

## Roadmap détaillée
- [ ] Renommer l’utilisateur serveur (`myuser` → valeur réelle) et factoriser les points communs avec `home/common.nix` dans un module `home/server/common.nix`.
- [ ] Créer `modules/server/base.nix` (utilisateur, SSH, pare-feu, swap éventuel, journald, auto-upgrade désactivé, configuration nix).
- [ ] Décrire l’infrastructure réseau (LAN, VLAN, DNS interne) pour préparer les services ; documenter dans `modules/server/networking.nix`.
- [ ] Ajouter un service simple de validation (ex. Syncthing ou Node exporter) pour tester la chaîne de déploiement.
- [ ] Documenter la procédure de déploiement distant (`nixos-rebuild --flake .#nixos-mini --target-host <ip>` + gestion des clés).
- [ ] Ébaucher la structure pour k0s (module ou service dédié) et inventorier les manifests existants.

## Questions à clarifier
- Utilisateur réel à utiliser sur les serveurs (actuellement `myuser`).
- Politique SSH (clés, port, restriction root, yubi?).
- Schéma de stockage (disques, RAID, ZFS?) et besoins de sauvegarde.
- Quelle version de NixOS viser (23.11 vs 24.05/unstable) pour les nouveaux nœuds.
- Topologie exacte du cluster (nombre de nœuds, rôles, ressources).

## Notes opérationnelles
- Toujours lancer `nix flake check` avant un déploiement serveur.
- Pour les tests en local, utiliser `nixos-rebuild build --flake .#nixos-mini` pour vérifier la génération.
- Les secrets doivent être ajoutés via `sops` et chiffrés avec les clés age déployées sur chaque machine (`~/.config/sops/age/keys.txt`). Exemple : `sops --encrypt --age <pubkey> secret.yml > secrets/<chemin>.yml`, puis laisser `home/common.nix` gérer la synchronisation dans `~/.kube/kubeconfig/`.
- Consigner toute nouvelle dépendance serveur dans `flake.lock` via `nix flake update --inputs-from .`.
- Garder `README.md` aligné avec l’avancement (ajouter les nouveaux services une fois opérationnels).
