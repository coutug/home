# Projet "home" - Configuration avec Nix

Ce document décrit la structure et les configurations du projet **home**, basé sur des fichiers `nix` pour gérer mes différents environnements. L'objectif est de centraliser et d'automatiser la gestion des machines personnelles et du cluster.

---

## Structure générale

- **Laptop** : configuration utilisateur via `home-manager` sur **EndeavourOS**
- **Desktop** : configuration utilisateur via `home-manager` sur **EndeavourOS**
- **Cluster** : machines avec **NixOS**, déploiement de services via `k0s`

---

## 1. Laptop

### Distribution
- **EndeavourOS** (base Arch Linux)

### Gestion de configuration
- `home-manager` avec Nix
- Certains paquets sont encore gérés via **pacman/yay** (logiciels spécifiques à Arch ou non disponibles dans Nixpkgs)

### Utilisation
- Machine de travail principale
- Applications installées :
  - Outils Kubernetes (`kubectl`, `helm`, `k9s`, etc.)
  - Outils DevOps (ex: `terraform`, `ansible`, `docker`)
  - Applications de productivité (éditeur de texte, navigateur, etc.)

---

## 2. Desktop

### Distribution
- **EndeavourOS** (base Arch Linux)

### Gestion de configuration
- `home-manager` avec Nix
- Certains paquets sont encore gérés via **pacman/yay**

### Utilisation
- Applications nécessitant un GPU performant
  - Jeux vidéo
  - Workloads liés à l’IA (entraîner ou tester des modèles)

### Logiciels principaux
- Pilotes GPU et dépendances CUDA/cuDNN
- Applications multimédia et gaming
- Outils IA (PyTorch, Tensorflow, etc.)

---

## 3. Cluster de petits serveurs

### Matériel
- Plusieurs petits ordinateurs peu performants
- Architecture homogène ou hétérogène (selon les machines disponibles)

### Gestion de configuration
- **NixOS** complet
- Orchestration avec **k0s** (distribution Kubernetes légère)

### Avantages
- Déploiement flexible de services
- Ajout/retrait de nœuds sans impact majeur
- Gestion déclarative via Nix

### Services à déployer
- **Vaultwarden** : gestion de mots de passe auto-hébergée
- **Syncthing** : synchronisation de fichiers (images, documents, etc.)
- **DNS** : service DNS interne (outil à définir, ex: `CoreDNS` ou `bind`)
- **Grafana** : visualisation et tableaux de bord
- **VictoriaMetrics** : base de données de séries temporelles pour monitoring
- **Vector** : collecte et routage des logs
- **Cron jobs** et services personnalisés (scripts maison, automatisations légères)

---

## Idées futures
- Ajout de monitoring plus avancé (Prometheus pour collecte métriques)
- Mise en place d’un CI/CD minimal pour déploiement des services
- Amélioration de la gestion des secrets (intégration plus poussée avec Vaultwarden)
- Déploiement de services orientés développement (Git, runners CI légers)