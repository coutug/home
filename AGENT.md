# AGENT.md — Règles et procédures pour ce dépôt Nix + Home Manager

## Objet
Ce document explique **comment modifier, tester et déployer** les configurations de ce dépôt
sur trois hôtes :
- **Laptop (EndeavourOS)** → `homeConfigurations.laptop`
- **Desktop (EndeavourOS)** → `homeConfigurations.desktop`
- **Mini serveur (NixOS)** → `nixosConfigurations.nixos-mini` (+ Home Manager en module)

> ⚠️ Sur EndeavourOS, Nix gère **l’environnement utilisateur** (Home Manager). Le système reste géré par `pacman`. **Ne pas** ajouter/retirer des paquets système via Nix.

---

## Arborescence du dépôt (vue d’ensemble)
.
├── flake.nix
├── flake.lock
├── hosts/
│ └── nixos-mini/ # modules/option NixOS propres au serveur
├── home/
│ ├── common.nix # configuration HM partagée
│ ├── laptop.nix # Laptop EndeavourOS
│ ├── desktop.nix # Desktop EndeavourOS
│ └── server.nix # Home Manager côté serveur (via module NixOS)
├── modules/ # modules réutilisables (nix, programs, overlays…)
│ └── nix.nix
└── secrets/ # fichiers chiffrés (sops-nix/agenix) — jamais en clair


**Convention d’attributs flake :**
- `homeConfigurations.laptop` et `homeConfigurations.desktop` ciblent les postes EndeavourOS.
- `nixosConfigurations.nixos-mini` est la config système du serveur NixOS, qui **importe** Home Manager comme module (`home-manager.users."<USER>" = import ./home/server.nix;`).

Adapter si nécessaire :
- `<USER>` : utilisateur unix.
- Si tes hôtes ont d’autres noms, renomme les attributs et fichiers correspondants.

---

## Règles de modification (où placer le code)

1. **Changement commun aux trois machines**
   - Modifier `home/common.nix` (packages, outils CLI, réglages XDG, shells, etc.).
   - Pour options Nix globales réutilisables, utiliser `modules/nix.nix`.

2. **Changement spécifique Laptop (EndeavourOS)**
   - Modifier `home/laptop.nix`.

3. **Changement spécifique Desktop (EndeavourOS)**
   - Modifier `home/desktop.nix`.

4. **Changement spécifique Serveur (NixOS)**
   - Modifier `hosts/nixos-mini/*` pour le **système** (services, réseaux, users, FS…).
   - Modifier `home/server.nix` pour le **home** (packages utilisateur, dotfiles…).

5. **Secrets**
   - Placer uniquement des **fichiers chiffrés** dans `secrets/` (via `sops-nix` ou `agenix`).
   - **Interdiction** d’ajouter des secrets en clair dans le repo.

6. **Paquets non libres**
   - Si nécessaire, gérer l’autorisation via un module dédié (ex : `modules/nix.nix`) plutôt qu’en ligne.

---

## Commandes usuelles (build, test, apply)

> Toutes les commandes se lancent **à la racine du dépôt**.

### 1) Vérifications rapides
```bash
# Affiche les sorties disponibles du flake
nix flake show

# Vérifie que la flake évalue et passe les checks (si définis)
nix flake check