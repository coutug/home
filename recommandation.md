# Recommandations d'amélioration

Ce document synthétise l'audit du dépôt. Les recommandations sont classées par
impact et ordre d'exécution. Elles visent sécurité, fiabilité opérationnelle et
reproductibilité ; elles n'impliquent pas de modifier des préférences
personnelles (thèmes, raccourcis, applications, disposition Hyprland).

## Contexte et périmètre

Le dépôt gère :

- deux postes Linux non-NixOS avec Home Manager (`laptop`, `desktop`) ;
- un cluster domestique NixOS/k0s à trois nœuds : `nixos-mini1` et
  `nixos-mini3` workers, `nixos-mini2` contrôleur et worker ;
- secrets SOPS : kubeconfigs, tokens k0s et Tailscale, mots de passe, clé SSH
  hôte et configuration OpenCode.

Points existants à préserver : flake verrouillé, Disko et chemins
`/dev/disk/by-id`, secrets hors du store Nix, permissions restrictives des
tokens runtime, authentification SSH par clé, et `stateVersion` historique.
La migration de nixpkgs vers 26.05 ne justifie pas de changer
`system.stateVersion = "25.11"` ou les `home.stateVersion`.

## Priorité 0 — correctifs sûrs et immédiats

### 1. Restreindre les kubeconfigs à l'utilisateur propriétaire

**Constat.** `home/common.nix` déploie les kubeconfigs SOPS en `0644`.
Un kubeconfig peut contenir un certificat, une clé client ou un token ; tout
utilisateur local peut actuellement le lire.

**Action.** Passer le mode à `0600` et assurer un répertoire parent en `0700`.

**Validation.** Construire le profil Home Manager puis, après activation
autorisée, contrôler :

```sh
stat -c '%a %U:%G %n' ~/.kube/kubeconfig/*
```

**Rollback.** Revenir temporairement au mode précédent uniquement si un autre
UID doit réellement consommer ces fichiers ; préférer alors une délégation
d'accès explicite.

### 3. Garantir nettoyage clé SSH temporairement déchiffrée

**Constat.** `scripts/prepare-host-key-extra-files` déchiffre clé SSH hôte dans
un répertoire temporaire sans `trap` local. Le flux normal de
`bootstrap-host` nettoie bien son répertoire, mais une exécution directe du
helper ou une erreur interne peut laisser clé privée dans `/tmp`.

**Action.** Définir contrat clair : helper autonome avec cleanup propre, ou
transfert explicite de responsabilité au parent après succès. Ajouter `trap`
pour erreurs/signaux, privilégier tmpfs et vérifier absence de résidu.

**Validation.** Provoquer échec contrôlé après création du répertoire et
contrôler qu'il a disparu.

### 4. Rendre token k0s réellement obligatoire pour workers

**Constat.** Mini1 et mini3 utilisent `pathExists` pour déclaration secret
k0s, mais activent toujours worker avec `tokenFile = "/etc/k0s/k0stoken"`.
Évaluation peut réussir puis service échouer au démarrage.

**Action.** Soit ajouter assertion d'évaluation claire lorsque rôle worker
exige token, soit conditionner service worker et secret ensemble si état
« préconfiguré mais non joint » est volontaire.

**Validation.** Dans copie temporaire, retirer fichier token : évaluation doit
échouer avec message explicite, pas au runtime.

### 5. Corriger aliases k9s

**Constat.** `home/programs/k9s.nix` imbrique `aliases` alors que module Home
Manager l'ajoute déjà. Le YAML généré risque `aliases.aliases.dp` au lieu de
`aliases.dp`.

**Action.** Retirer niveau interne redondant.

**Validation.** Inspecter `aliases.yaml` dans résultat activation puis tester
aliases dans k9s.

### 6. Corriger plugin Zsh `kmux`

**Constat.** Le plugin appelle `exit 1` depuis fonctions sourcées : une erreur
peut fermer shell interactif. L'annulation FZF peut ensuite appeler tmuxp avec
nom vide.

**Action.** Remplacer `exit` par `return`, vérifier résultat FZF, citer
variables et utiliser `$HOME`.

**Validation.** Tester répertoire absent, kubeconfig absent, liste vide et
annulation FZF dans shell jetable.

### 7. Corriger fallback de sortie Hyprland

**Constat.** `hyprctl dispatch 'hl.dsp.exit()'` est expression Lua, pas
dispatcher Hyprland valide.

**Action.** Employer dispatcher réellement supporté par version installée,
vraisemblablement `hyprctl dispatch exit`.

**Validation.** Vérifier documentation de version Hyprland puis tester dans
session non critique.


## Priorité 1 — sécurité et disponibilité cluster

### 11. Compléter bootstrap Tailscale

**Constat.** `scripts/bootstrap-host` ajoute nouvelle identité aux règles k0s
et users, jamais à politique/secret Tailscale. Hôte réinstallé peut donc ne pas
activer Tailscale.

**Action.** Le bootstrap doit valider hostname contre `nixosConfigurations`,
mettre à jour règle et secret Tailscale propres à hôte, lancer `sops updatekeys`

**Bénéfice.** Bootstrap complet et déterministe.

### 14. Pinner sources Helm et images runtime

**Constat.** Charts Helm sont obtenus auprès dépôts distants à installation.
Images vLLM/k9s utilisent tags, dont `ubuntu:latest`; modèle Hugging Face n'a
pas révision. Deux machines peuvent exécuter bits différents sous même config.

**Action.**

- images OCI par digest ;
- modèle par révision/commit ;
- remplacer `latest` ;
- envisager OCI/digest ou miroir/cache vérifié pour charts Helm ;
- documenter processus de mise à jour des digests.

**Validation.** Résoudre digests, démarrer après préchargement sans accès
amont, comparer digests exécutés.

### 15. Décider politique d'accès administrateur cohérente

**Constat conditionnel.** Root SSH par clé est permis, même clé est autorisée
pour root et `gabriel`, et `gabriel` a sudo sans mot de passe. Mini1/mini3 le
déclarent aussi Nix trusted user. Durcir un seul élément ne réduit pas accès,
car compte `gabriel` possède déjà root via sudo.

**Action seulement si modèle de menace le justifie.** Politique cohérente :
interdire root SSH, exiger authentification sudo ou limiter commandes, retirer
`trusted-users` sans besoin démontré, et utiliser clés distinctes/certificats
SSH à durée limitée.

**Décisions préalables.** Besoin bootstrap/récupération distante, accès console,
environnement mono-utilisateur et modèle de menace.

## Priorité 2 — reproductibilité Home Manager

### 16. Choisir gestionnaire des dépendances workstation

Le profil se déclare `genericLinux`, mais mélange paquets Home Manager et
prérequis système implicites.

**Incohérences confirmées.**

- `EDITOR=nvim`, alias `nv=nvim` et VSCodium configuré pour `/usr/bin/nvim`,
  mais `neovim` n'est pas déclaré ;
- paquet installé : `vscodium`, alors que fonctions/raccourcis appellent
  `code` ;
- Hyprland appelle Waybar, Dunst, Hyprpaper, Hypridle, Hyprlock, Fuzzel,
  Dolphin, Brave, Obsidian, Discord, `wpctl`, `brightnessctl`, `playerctl`,
  agent polkit et police JetBrainsMono Nerd Font sans tous les déclarer ;
- shell suppose entre autres `jq`, `bc`, `curl`, `nc`, `xclip`, tmuxp et k9s ;
- Quadlet vLLM suppose Podman/Quadlet, CDI NVIDIA et lingering utilisateur.

**Action.** Choisir l'un des deux modèles et l'appliquer :

1. **Profil autonome recommandé :** déclarer dépendances via Home Manager/Nix,
   utiliser chemins exécutables Nix/PATH (`nvim`, `codium`), et installer police
   requise.
2. **Profil complémentaire distribution :** documenter prérequis par profil et
   ajouter assertions/checks de présence au lieu de laisser échecs runtime.

Ne pas affirmer reproductibilité complète tant que second modèle reste implicite.

### 17. Aligner Neovim, VSCodium, extensions et formatteurs

**Action.** Installer Neovim ou abandonner `nvim`; remplacer `/usr/bin/nvim`
par exécutable présent dans PATH; utiliser `codium` si VSCodium est cible;

**Validation.** Dans PATH propre du profil :

```sh
command -v nvim codium
codium --list-extensions --show-versions
```

Tester fichiers Nix, Python, Java, XML, shell et Markdown.

### 19. Rendre vLLM opérationnel et protégé

**Action.** Au-delà du pinning images : déclarer/valider Podman, Quadlet et CDI
NVIDIA ; documenter lingering ; rendre IP/modèle/config paramétrables ; vérifier
ACL Tailscale ; ajouter clé API stockée SOPS si service est consommable par des
pairs non entièrement fiables.

**Validation.** `podman info`, état service utilisateur, disponibilité CDI,
requête autorisée et refus sans autorisation.

### 20. Séparer Zsh core, workstation et serveur

**Constat.** `home/server.nix` importe module Zsh workstation : aliases Arch
(`pacman`, `yay`), Docker/minikube/lazygit et plugins dépendant outils absents
sont présents sur NixOS serveur.

**Action.** Extraire `zsh-core.nix`, puis couches workstation, Kubernetes et
serveur. Faire cette refactorisation avec correction dépendances ; pas seule.

### 21. Corriger tmux et Atuin

- `tmux.conf` duplique `tmux-resurrect`/`tmux-yank`, déclare TPM sans le
  démarrer et utilise `xclip` non déclaré. Gérer plugins par Home Manager ou
  installer/invoquer TPM explicitement ; dédupliquer et déclarer backend presse-
  papier adapté.
- thème Atuin est marqué « fonctionne pas », mal structuré/non sélectionné.
  Corriger selon format courant et le sélectionner, ou supprimer bloc mort.
- `auto_sync = true` Atuin peut synchroniser historique shell contenant secrets.
  Définir politique de filtrage et destination ou désactiver sync automatique.

### 22. Durcir plugins shell et k9s

- endpoints inventaire HTTP : privilégier HTTPS/auth, `curl --fail`, validation
  JSON avec `jq --arg`, variables citées et `return` plutôt que `exit` ;
- plugins k9s utilisant pipes vers `less` : activer `pipefail` pour ne pas
  masquer échecs ;
- plugin PVC : nom pod temporaire unique, `trap` de suppression, timeout ;
- plugin Vector : commande et description divergent (`vector tap` contre
  `vector top`) ; corriger commande ou libellé.

## Priorité 3 — garde-fous qualité et maintenance

### 23. Ajouter formatter, checks et CI non déployante

**Constat.** Flake ne définit ni `formatter`, ni `checks`; aucun workflow CI.
`nix flake check` exigé par règles projet ne couvre pas forcément profils Home
Manager sans checks explicites.

**Action.** Exposer :

```text
formatter.x86_64-linux
checks.x86_64-linux
├── home-laptop
├── home-desktop
├── nixos-mini1
├── nixos-mini2
├── nixos-mini3
├── shellcheck
├── nix-format
└── secret-policy-check
```

CI doit évaluer/build selon coût acceptable, formater, lancer ShellCheck,
valider enveloppes SOPS et ne jamais déchiffrer ni déployer. Commencer par
évaluations + checks légers si builds complets sans cache coûtent trop cher.

### 24. Ajouter tests scripts bootstrap

Tester au minimum :

- arguments manquants ;
- hostname inconnu/refusé ;
- idempotence insertion recipient SOPS ;
- préflight dépendances (`sops`, `ssh-to-age`, Nix, SSH) ;
- annulation utilisateur ;
- cleanup répertoire clé privée après échec ;
- absence token/Tailscale ;
- absence de déploiement tant que branche/commit attendu non disponible.

Le bootstrap doit utiliser version `nixos-anywhere` venant du flake ou révision
explicite, pas dernière version GitHub flottante.

### 25. Normaliser format et contrôles fichiers

- exposer `nixfmt` dans flake et l'appliquer aux fichiers Nix ;
- utiliser ShellCheck pour scripts Bash ;
- ajouter `zsh -n`/tests ciblés plugins ;
- étendre `.gitignore` à `/result*` et `.direnv/` ;
- ajouter détection plaintext secrets (un ignore ne remplace pas scan) sans
  bloquer fichiers SOPS légitimes.

### 26. Maintenance Nix et stockage

- définir `boot.loader.systemd-boot.configurationLimit` ;
- GC Nix planifié avec politique conservatrice ;
- surveiller espace ESP, `/nix/store`, racine et volumes ;
- activer surveillance SMART adaptée aux disques ;
- mesurer capacité k0s : `/var/lib/k0s` reste sur racine de 150 Gio tandis que
  volumes `/data-root` et `/data-ext` existent ; migrer dataDir seulement avec
  sauvegarde et procédure rollback.

## Priorité 4 — structure, après stabilisation

### 27. Extraire politique commune des minis

Les trois configurations dupliquent boot, SSH, utilisateurs, sudo, firewall,

**Action.** Après durcissement réseau/secrets, introduire progressivement :

```text
modules/nixos/mini-base.nix
modules/nixos/k0s-worker.nix
modules/nixos/k0s-controller.nix
```

Centraliser politique, avec paramètres explicites pour rôle, adresse,
interface/CIDR, token, secret Tailscale et dataDir. Ne pas entreprendre cette
refactorisation comme changement cosmétique isolé.

### 28. Retirer ou documenter éléments orphelins

- copie racine `kubie.yaml` semble dupliquer `home/config/kubie.yaml` alors que
  seule seconde est déployée ; supprimer si aucun usage externe ;
- `modules/.gitkeep` est devenu inutile ;
- skin k9s alternatif généré mais non sélectionné : supprimer ou documenter
  choix manuel ;
- `.gitignore` OpenCode non déployé : intégrer ou retirer ;
- complétions vendoriées pour outils absents : supprimer, documenter ou générer
  depuis paquet réellement installé.

## Ordre d'exécution proposé

1. Kubeconfig `0600`; lock écran; cleanup clé; assertions tokens; petits bugs
   k9s/Zsh/Hyprland; documentation factuelle.
2. Décider topologie firewall, modèle accès admin, RPO/RTO et politique SOPS.
3. Restreindre firewall; segmenter recipients; compléter bootstrap Tailscale;
   mettre snapshots etcd testés; stabiliser Cilium.
4. Définir frontière Home Manager/OS; aligner Neovim/Codium; rendre extensions
   moins impératives; pinner vLLM/images/charts; sécuriser vLLM.
5. Ajouter formatter, checks, CI et tests bootstrap.
6. Mesurer stockage et maintenance Nix, puis factoriser hôtes et Zsh.

## Actions à ne pas faire automatiquement

- ne pas augmenter `stateVersion` pour suivre nixpkgs ;
- ne pas restreindre firewall sans flux/interface/CIDR confirmés ;
- ne pas retirer root SSH ou sudo sans stratégie de récupération ;
- ne pas segmenter recipients sans confirmer politique de récupération et
  rotation ;
- ne pas passer à trois contrôleurs sans RPO/RTO et capacité définis ;
- ne pas activer chiffrement disque sans modèle de menace et procédure de
  déverrouillage ;
- ne pas refactoriser structure uniquement pour style ;
- ne pas modifier thèmes, raccourcis, choix logiciels ou disposition Hyprland
  sans besoin explicite.
