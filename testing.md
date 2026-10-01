# Guide de vérification et de tests

Ce dépôt gère deux profils Home Manager sur Linux non-NixOS (`laptop`,
`desktop`) et trois hôtes NixOS/k0s (`nixos-mini1`, `nixos-mini2`,
`nixos-mini3`). Il contient aussi des secrets chiffrés avec SOPS, des scripts
de bootstrap et une configuration Disko pour les disques.

Ce document explique comment vérifier ces configurations sans les déployer,
quels tests ajouter progressivement, et ce que chaque niveau de test prouve ou
ne prouve pas.

> **État actuel :** le dépôt ne déclare pas encore `checks.<system>`,
> `formatter.<system>`, tests automatisés ou CI. Les commandes et structures
> marquées **à ajouter** sont des recommandations, pas des fonctionnalités déjà
> disponibles.

## 1. Règles de sécurité

Ne pas exécuter sans accord explicite :

- `home-manager switch` ;
- `nixos-rebuild test`, `switch` ou `boot` ;
- `nixos-anywhere` ;
- Disko en mode qui partitionne, formate ou monte des disques réels ;
- `scripts/bootstrap-host` contre une machine réelle.

`scripts/bootstrap-host` termine par `nixos-anywhere`. Les configurations
`disk-config.nix` visent de vrais identifiants `/dev/disk/by-id/...` et peuvent
donc détruire les données des disques ciblés.

Ne jamais :

- placer une clé Age privée de production dans CI ;
- déchiffrer un secret de production dans logs, artefacts, cache ou `/nix/store` ;
- transmettre secrets réels à un test VM ou à un mock ;
- considérer un build comme une preuve que secrets réels, réseau ou matériel
  fonctionneront.

## 2. Vocabulaire Nix

| Niveau | Ce qui se passe | Ce qui ne se passe pas |
|---|---|---|
| **Évaluation** | Nix lit fichiers, résout imports, options, types et assertions, puis produit graphe de dérivations. | Aucun service ne démarre, aucun fichier de profil n'est activé. |
| **Build** | Nix télécharge ou construit résultats dans `/nix/store`. | Aucune modification du système cible ou du `$HOME` cible. |
| **Activation** | Home Manager écrit/liens fichiers dans `$HOME`; NixOS modifie système actif et peut démarrer services. | Ce n'est plus un test sans effet. |
| **Déploiement / installation** | Configuration est copiée/activée sur autre machine. Avec Disko, disques peuvent être repartitionnés. | Rien : c'est opération réelle. |

`--no-link` empêche création du lien local `result`. Il **n'empêche pas** un
build d'écrire dans `/nix/store` ni de consommer réseau, CPU et espace disque.

## 3. Cibles à couvrir

| Type | Cible | Entrée principale |
|---|---|---|
| Home Manager | `laptop` | `home/laptop.nix` → `home/common.nix` |
| Home Manager | `desktop` | `home/desktop.nix` → `home/common.nix` |
| NixOS/k0s worker | `nixos-mini1` | `hosts/nixos-mini1/configuration.nix` |
| NixOS/k0s controller + worker | `nixos-mini2` | `hosts/nixos-mini2/configuration.nix` |
| NixOS/k0s worker | `nixos-mini3` | `hosts/nixos-mini3/configuration.nix` |

Les modules partagés à tester sont surtout :

- `modules/nixos/mini-tailscale.nix` ;
- `modules/nixos/mini-sops-bootstrap.nix` ;
- `hosts/k0s/k0s-config.nix` ;
- `home/programs/*.nix` ;
- `scripts/bootstrap-host`, `scripts/generate-host-key-secret` et
  `scripts/prepare-host-key-extra-files`.

## 4. État actuel et limites de `nix flake check`

`flake.nix` expose deux `homeConfigurations`, trois `nixosConfigurations` et
le paquet `k0s`. Il n'expose actuellement ni `checks` ni formatter.

`nix flake check` :

1. évalue sorties standard reconnues par Nix ;
2. vérifie notamment que les sorties NixOS ont une dérivation
   `config.system.build.toplevel` ;
3. construit les dérivations sous `checks.<system>`, si elles existent.

Il ne lance pas de service, ne déchiffre pas SOPS et ne valide pas matériel,
réseau ou secrets réels. `homeConfigurations` n'est pas une sortie standard
que `nix flake check` couvre comme check explicite. Les deux profils Home
Manager doivent donc être évalués ou construits explicitement.

`nix flake show` sert à inventorier sorties. Ce n'est pas un test runtime.
`nix flake update` modifie `flake.lock`; ce n'est pas une vérification.

## 5. Préparation locale

Exécuter commandes depuis racine du dépôt et vérifier état Git :

```bash
git status --short
nix --version
nix flake show --all-systems
```

Prévoir assez d'espace pour `/nix/store`, particulièrement avant builds NixOS
ou VM. Utiliser `--no-update-lock-file` pour garantir qu'une vérification ne
modifie pas le verrouillage des dépendances.

Attention : une flake issue de Git n'inclut normalement que fichiers suivis.
Un fichier présent mais non suivi peut sembler disponible localement, tout en
étant absent dans CI ou après commit. Ceci est important ici car le dépôt
utilise `pathExists` et `readDir` pour matériel mini3, tokens k0s, secret
OpenCode et kubeconfigs.

## 6. Vérifications rapides, non activantes

### 6.1 Évaluation flake

```bash
nix flake check --no-build --no-update-lock-file
```

**Pourquoi :** détecte imports cassés, options inconnues, conflits de modules,
types incorrects et assertions Nix existantes.

**Succès attendu :** commande retourne code `0`. Aujourd'hui, elle ne construit
pas de checks supplémentaires car aucun `checks` n'est déclaré.

### 6.2 Évaluation explicite Home Manager

```bash
for profile in laptop desktop; do
  nix eval --raw ".#homeConfigurations.$profile.activationPackage.drvPath"
done
```

**Pourquoi :** force les deux graphes Home Manager, que `nix flake check` ne
couvre pas explicitement.

### 6.3 Évaluation explicite NixOS

```bash
for host in nixos-mini1 nixos-mini2 nixos-mini3; do
  nix eval --raw ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath"
done
```

**Pourquoi :** force chaque configuration système et ses modules Home Manager
embarqués.

Ces trois groupes de commandes n'activent aucune configuration.

## 7. Builds non déployants

Après évaluations réussies, construire les résultats sans créer `result` :

```bash
for profile in laptop desktop; do
  nix build --no-link ".#homeConfigurations.$profile.activationPackage"
done

for host in nixos-mini1 nixos-mini2 nixos-mini3; do
  nix build --no-link ".#nixosConfigurations.$host.config.system.build.toplevel"
done
```

**Pourquoi :** valide que les fermetures Nix peuvent être construites ou
récupérées depuis caches, sans activer profil ou système.

**Limite importante :** construire `activationPackage` Home Manager ne lance
pas les scripts d'activation. C'est souhaité ici : `home/common.nix` contient
un backup VSCodium et une synchronisation qui installe/désinstalle extensions.
Ces scripts peuvent modifier `$HOME` dès activation. Ne pas présenter un
dry-run Home Manager comme garantie d'absence de mutation tant que scripts ne
respectent pas explicitement `$DRY_RUN_CMD`.

## 8. Contrôles statiques

Un contrôle statique lit code ou le parse sans démarrer infrastructure. Il est
rapide et adapté à chaque modification.

### À ajouter

| Outil | Cible | But |
|---|---|---|
| `nixfmt` | `*.nix` | Format cohérent et diff lisible. |
| `statix`, `deadnix` | Nix | Anti-patterns et code inutilisé. |
| `bash -n`, `shellcheck`, `shfmt` | scripts Bash | Syntaxe, erreurs shell fréquentes, format. |
| `zsh -n` | plugins/completions Zsh | Syntaxe Zsh. |
| `luac -p`, `stylua`, `luacheck` | Hyprland/WezTerm Lua | Syntaxe, format, usages suspects. |
| parseur YAML/JSON/JSONC | configs | Syntaxe et structure. |
| `sops filestatus` | secrets chiffrés | Vérifie enveloppe chiffrée sans afficher contenu. |

Exemples ponctuels :

```bash
nix fmt -- --check
bash -n scripts/bootstrap-host scripts/generate-host-key-secret \
  scripts/prepare-host-key-extra-files home/config/code/scripts/*.sh
zsh -n home/config/omz-custom/plugins/*/*.zsh home/dotfiles/p10k.zsh
luac -p home/config/wezterm/*.lua home/config/hypr/*.lua home/config/hypr/config/*.lua
```

`nix fmt` exigera ajout futur de `formatter.x86_64-linux` au flake. Avant cet
ajout, appeler directement version épinglée de `nixfmt` depuis environnement
Nix adapté.

La syntaxe valide ne prouve pas qu'une API existe : par exemple, Lua peut être
valide alors qu'une commande Hyprland est invalide au runtime.

## 9. Assertions Nix : empêcher états incohérents

Une assertion Nix exprime invariant métier. Si faux, évaluation échoue avec
message clair, avant build ou déploiement. C'est meilleur qu'un échec tardif
sur machine.

Structure générale :

```nix
assertions = [
  {
    assertion = condition;
    message = "Explication claire de l'invariant violé.";
  }
];
```

### Assertions recommandées

| Priorité | Invariant | Justification dépôt |
|---|---|---|
| P0 | Worker k0s actif ⇒ fichier token source existe, secret est déclaré et chemin `tokenFile` correspond. | mini1/mini3 gardent `tokenFile` même si `pathExists` masque le secret. |
| P0 | `enablePasswordSecrets` ⇒ `secrets/users/mini.yaml` existe et secrets password sont déclarés. | Module SOPS masque actuellement absence fichier. |
| P0 | Kubeconfigs Home Manager ont mode `0600`. | Ils peuvent contenir token, certificat ou clé client ; mode actuel est `0644`. |
| P1 | Deux disques Disko ⇒ identifiants root/data distincts. | Évite cible identique accidentelle pour mini1/mini2. |
| P1 | Routes Tailscale non vides ⇒ routage serveur/both et IPv4 forwarding actif. | Rend contrat subnet-router explicite. |
| P1 | SSH activé ⇒ clés administrateur non vides et mot de passe SSH désactivé. | Rend politique accès vérifiable. |
| P1 | Controller k0s ⇒ adresse API, SAN etcd et valeur Cilium proviennent même source. | `192.168.0.12` est répétée dans `k0s-config.nix`. |
| P2 | Sortie production mini3 ⇒ matériel présent. | Import matériel est actuellement conditionnel dans flake. |

Ne pas ajouter assertion basée sur secret déchiffré : SOPS déchiffre à
l'activation, pas pendant évaluation. Tester présence de fichier, déclaration,
format, chemin et permissions, jamais valeur secrète.

## 10. Futurs `checks` du flake

**À ajouter** dans `flake.nix` :

```text
checks.x86_64-linux
├── home-laptop
├── home-desktop
├── nixos-mini1
├── nixos-mini2
├── nixos-mini3
├── nix-format
├── shellcheck
├── secret-policy
└── tests-vm-ciblés
```

Les cinq premiers exposeront les dérivations déjà produites par profils et
hôtes. `nix flake check` pourra alors les construire. Le formatter permettra :

```nix
formatter.x86_64-linux = pkgs.nixfmt;
```

Ce mécanisme centralise validation : même commande locale et CI. Garder checks
rapides sur chaque pull request ; déplacer builds très lourds et VMs au nightly
si nécessaire.

## 11. Tests Home Manager

### Priorité immédiate

1. Évaluer et construire `laptop` et `desktop`.
2. Lire valeurs évaluées importantes avec `nix eval`.
3. Inspecter fichiers générés après build, sans les activer.
4. Tester scripts mutateurs dans sandbox.

Valeurs/fichiers à contrôler :

- permissions et chemin des kubeconfigs ;
- structure `programs.k9s.aliases` : alias attendu directement, pas
  `aliases.aliases.dp` ;
- configuration Quadlet vLLM générée ;
- `.zshrc`, chemins XDG et fichiers liés ;
- programmes référencés par alias/plugins réellement déclarés ;
- contenu de fichiers YAML/JSON/Lua générés ou liés.

Exemple d'inspection de valeur :

```bash
nix eval --json '.#homeConfigurations.laptop.config.sops.secrets' \
  --apply 'secrets: secrets."kubeconfig/nixos-mini.yml".mode'
```

Adapter nom du secret si inventaire kubeconfigs change.

### NMT : utile, mais ciblé

Home Manager utilise NMT pour ses propres tests de modules : configuration
minimaliste, génération fichier, comparaison avec résultat attendu (« golden
test »). Dans ce dépôt, NMT devient pertinent après extraction de vrais modules
réutilisables, par exemple module K9s, vLLM ou Zsh core.

Ne pas commencer par NMT pour profils complets : build des profils, assertions
et sandbox scripts donnent ici meilleur gain. NMT ne teste ni GUI, GPU, réseau,
Podman, extensions VSCodium, activation réelle ou secrets runtime.

## 12. Tests scripts dans sandbox

Les scripts bootstrap écrivent des règles SOPS, créent secrets et peuvent
déployer. Les tester uniquement dans environnement jetable.

### Technique recommandée : Bats + mocks

Créer pour chaque test :

1. copie temporaire du dépôt initialisée avec Git ;
2. `$HOME`, `TMPDIR` et secrets fixtures temporaires ;
3. répertoire `bin/` injecté au début de `PATH` ;
4. faux `sops`, `nix`, `ssh`, `ssh-keygen`, `ssh-to-age`, `codium`, `fzf`,
   `tmuxp` et autres commandes externes ;
5. journal des appels et arguments ;
6. mocks qui refusent réseau, hôtes réels, `/etc`, `/home/gabriel` et tout
   chemin hors répertoire test.

Les mocks ne doivent jamais journaliser stdin ou variables pouvant contenir un
secret. Utiliser clés et secrets synthétiques, jamais ceux du dépôt.

### Scénarios bootstrap prioritaires

| Script | Cas à tester |
|---|---|
| `generate-host-key-secret` | arité, hostname invalide (`..`, slash, saut ligne), secret existant, échec `ssh-keygen`/`ssh-to-age`/`sops`, absence fichier partiel, cleanup temporaire. |
| `prepare-host-key-extra-files` | secret absent, structure générée, permissions, échec première/deuxième extraction, `SIGINT`/`SIGTERM`, absence clé résiduelle. |
| `bootstrap-host` | hôte inconnu, IP/identité invalides, dépendance absente, refus utilisateur, insertion recipient idempotente, préflight Git, token worker absent, Tailscale absent, rollback après erreur, commande finale observée mais jamais lancée. |
| scripts VSCodium | liste extensions, install/uninstall, erreur commande, absence mutation hors sandbox. |
| plugins Zsh | annulation FZF, données malformées, erreurs commande, fonction retourne sans fermer shell. |

Tester aussi états négatifs : un bon test montre qu'une configuration invalide
échoue tôt, avec message compréhensible.

## 13. SOPS : contrôles sans fuite

SOPS est compatible avec builds : fichiers chiffrés peuvent entrer dans store
sans clé privée. Déchiffrement réel intervient à l'activation sur hôte/profil.

### Contrôles sûrs pour CI et local

- inventaire des secrets attendus ;
- `sops filestatus` pour chaque fichier secret ;
- présence métadonnées SOPS et destinataires attendus ;
- contrôle des permissions déclarées (`0400`, `0600`, etc.) ;
- détection de clés privées ou credentials accidentellement committés ;
- vérification que fichiers référencés par configuration existent et sont suivis.

Ne pas supposer qu'un secret est toujours YAML ni que chaque champ est
`ENC[...]` :

- `secrets/tailscale/mini*` sont binaires chiffrés sans extension ;
- `secrets/opencode/*` sont des secrets binaires chiffrés sans extension, déployés comme fichiers séparés sous `~/.config/opencode/` ;
- `docs/network.md` est une enveloppe SOPS malgré extension Markdown.

Pour tester chiffrement/déchiffrement, créer fixture isolée avec identité Age
éphémère et clé publique de test. Vérifier ajout/retrait destinataire et
`updatekeys`, sans toucher secrets réels.

## 14. Tests NixOS en VM

Nixpkgs fournit `pkgs.testers.runNixOSTest`. Il construit une ou plusieurs VM
QEMU et exécute script Python avec méthodes comme `wait_for_unit`, `succeed` et
`fail`.

Squelette :

```nix
pkgs.testers.runNixOSTest {
  name = "mini-ssh";
  nodes.machine = { ... }: {
    # Importer module sous test avec valeurs et secrets de test.
  };
  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("systemctl is-enabled sshd.service")
  '';
}
```

### Premiers tests VM recommandés

1. module `mini-tailscale` avec secret synthétique : unité, flags et
   permissions ;
2. module `mini-sops-bootstrap` : clé hôte injectée avant SOPS, secrets users
   fixtures, reboot et empreinte stable ;
3. politique commune d'un mini : utilisateur `gabriel`, SSH, sudo, sysctl et
   firewall attendus ;
4. Home Manager embarqué : shell et paquets annoncés disponibles ;
5. Disko sur disque virtuel, séparé du test système.

### Limites des VM

Une VM ne prouve pas : firmware, microcode, noms réels de NIC ou disques,
GPU/CDI NVIDIA, comportement couvercle mini3, ACL Tailscale, routeur DHCP,
réseau L2 physique, performance/SMART disques ou validité secrets réels.

Un test k0s à trois nœuds avec Cilium est possible, mais coûteux : chart Helm
téléchargé à installation, eBPF/réseau QEMU et ressources importantes. Le
placer d'abord en nightly ou manuel, jamais comme garde PR initiale.

## 15. Disko : tests uniquement sur stockage jetable

Disko partitionne et formate entièrement dispositifs configurés. Ne pas lancer
sur machine locale ou CI standard avec configuration réelle.

Stratégie :

1. évaluer configuration Disko et assertions de structure ;
2. inspecter scripts générés par version verrouillée ;
3. créer VM jetable avec un ou deux disques virtuels ;
4. surcharger chemins `/dev/disk/by-id/...` uniquement pour test ;
5. lancer Disko dans VM ;
6. vérifier GPT, ESP vfat 512 MB, racine ext4 150 GB, montages, séparation
   root/data et reboot UEFI.

Ajouter cas négatifs : disque manquant, disque trop petit et deux cibles égales
doivent échouer clairement. Cela ne valide ni modèle, numéro de série, santé ou
capacité du matériel réel. Ces vérifications restent manuelles avant bootstrap.

## 16. Validation runtime manuelle, après activation autorisée

Tests précédents réduisent risque. Ils ne remplacent pas validation réelle.
Après déploiement approuvé, vérifier au minimum :

### Hôtes NixOS

- démarrage et possibilité rollback bootloader ;
- empreinte SSH attendue ;
- utilisateur `gabriel`, accès SSH et sudo selon politique ;
- services `k0s`, `tailscaled`, SOPS ;
- chemins/propriétaires/modes de secrets, sans afficher contenu ;
- espace/inodes de `/`, `/nix/store`, `/var/lib/k0s`, `/boot`, données ;
- SMART et état des disques ;
- reboot contrôlé et retour services.

### Cluster k0s

- controller et workers `Ready` ;
- Cilium DaemonSet/operator prêts ;
- DNS et trafic pod-à-pod ;
- accès API depuis utilisateur autorisé ;
- stockage et logs ;
- sauvegarde/restauration etcd testée selon RPO/RTO choisi.

### Tailscale et réseau

- hôte joint tailnet avec hostname attendu ;
- ACL et clé auth valides ;
- route annoncée approuvée et atteignable ;
- flux exposés limités aux interfaces/sources voulues ;
- adresse DHCP controller correspond à adresse API k0s déclarée.

### Home Manager

- Kubeconfigs non lisibles par autres utilisateurs ;
- session shell sans erreurs ;
- applications/outils requis disponibles ;
- fichiers VSCodium et extensions : vérifier effet avant d'autoriser scripts
  mutateurs ;
- Hyprland/vLLM uniquement dans environnement contrôlé adapté.

## 17. CI non déployante à ajouter

Une CI doit exécuter validation sans machine cible ni clés privées :

```text
checkout
├── contrôle format / lint / syntaxes
├── politique SOPS sans déchiffrement
├── nix flake check --no-build
├── évaluation explicite des 2 profils Home Manager
├── évaluation explicite des 3 hôtes NixOS
├── builds selon coût/cache
└── tests scripts sandboxés et VMs ciblées selon fréquence
```

Ne pas donner à CI : clé Age de production, mot de passe, accès SSH, token
Tailscale, kubeconfig réel ou permission de déployer. Les caches binaires
accélèrent builds, mais ne doivent jamais recevoir plaintext.

| Niveau | Contenu | Fréquence |
|---|---|---|
| P0 | Format, lint, évaluation cinq cibles, politique SOPS | Chaque commit/PR |
| P1 | Build deux profils et trois systèmes | PR ou branche principale, selon cache |
| P2 | Bats sandbox et VMs module ciblés | Branche principale ou nightly |
| P3 | k0s multi-VM, Disko VM complet | Nightly ou manuel |
| P4 | Activation, reboot, réseau, matériel et cluster réel | Maintenance manuelle planifiée |

## 18. Diagnostic et nettoyage

En cas d'échec :

1. relancer étape la plus petite ;
2. ajouter `--show-trace` pour erreur Nix difficile ;
3. ajouter `-L` à `nix build` pour logs build ;
4. lire assertion/message avant modifier configuration ;
5. ne pas contourner une assertion sans comprendre invariant.

Après essais :

- supprimer liens `result` éventuels, pas contenus `/nix/store` directement ;
- supprimer VMs, disques et fixtures temporaires ;
- vérifier `git status --short` ;
- vérifier qu'aucun fichier déchiffré n'est resté dans dépôt ou `/tmp` ;
- utiliser mécanismes NixOS/Home Manager de générations et rollback seulement
  après activation explicitement autorisée.

## 19. Checklists

### Avant commit ou PR

- [ ] Tous fichiers voulus sont suivis par Git.
- [ ] Aucun secret en clair ni clé privée.
- [ ] Format/lint/syntaxe réussissent.
- [ ] `nix flake check --no-build --no-update-lock-file` réussit.
- [ ] Deux profils Home Manager et trois hôtes sont explicitement évalués.
- [ ] Les assertions nouvelles ont test positif et négatif.

### Avant activation Home Manager

- [ ] Build `activationPackage` réussi.
- [ ] Scripts d'activation lus et effets compris.
- [ ] Backup VSCodium et synchronisation extensions explicitement acceptés.
- [ ] Sauvegarde des données utilisateur existantes.
- [ ] Chemins secrets et permissions attendues vérifiés dans résultat évalué.

### Avant déploiement NixOS ou bootstrap

- [ ] `nix flake check --no-update-lock-file` réussi avant push et déploiement.
- [ ] Build toplevel hôte réussi.
- [ ] Hostname, rôle k0s, IP controller, DNS et routes confirmés.
- [ ] Disques identifiés par modèle, série, taille et chemin `/dev/disk/by-id`.
- [ ] Sauvegarde testée et fenêtre maintenance définie.
- [ ] Secrets chiffrés, destinataires et clés récupération vérifiés.
- [ ] Worktree propre, diff relu, commit poussé.
- [ ] Procédure rollback et accès console disponibles.

## 20. Ordre d'implémentation recommandé

1. Corriger invariants critiques, surtout token worker, secrets users et modes
   kubeconfig ; ajouter assertions correspondantes.
2. Ajouter formatter et checks d'évaluation/build pour cinq cibles.
3. Ajouter lint/syntaxe et politique SOPS sans déchiffrement.
4. Écrire Bats pour scripts bootstrap avec fixtures/mocks sûrs.
5. Ajouter VM SOPS/Tailscale/SSH ciblées.
6. Ajouter Disko VM et tests k0s plus lourds quand architecture réseau et
   stockage seront stabilisés.
7. Ajouter CI non déployante puis checklist runtime de maintenance.

Ne pas utiliser tests pour justifier changement de politique non décidé :
restriction firewall, segmentation destinataires SOPS, root SSH, chiffrement
disque, topologie control-plane ou migration stockage exigent d'abord décision
opérationnelle et procédure récupération.

## 21. Références

- [Nix : `nix flake check`](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake-check.html)
- [NixOS : tests d'intégration VM](https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html)
- [Home Manager : tests et NMT](https://nix-community.github.io/home-manager/contributing/tests.html)
- [Home Manager : flakes standalone](https://nix-community.github.io/home-manager/nix-flakes/standalone.html)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [Disko : quickstart et avertissement destructif](https://github.com/nix-community/disko/blob/master/docs/quickstart.md)
- [nix.dev : CI GitHub Actions](https://nix.dev/guides/recipes/continuous-integration-github-actions.html)
