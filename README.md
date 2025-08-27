# Nix Home Manager Configurations

Configuration Nix et Home Manager pour trois machines :

- **Laptop** (EndeavourOS)
- **Desktop** (EndeavourOS)
- **nixos-mini** (serveur NixOS)

## Services
- Passky
- Syncthing

## Commandes utiles

```bash
nix flake update
nix flake show
nix flake check
```


## Installation

> Lorsque l’installeur demande si tu veux installer **Determinate Nix**, réponds **NO**.

```bash
## Install Nix
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

## Run home-manager
nix run github:nix-community/home-manager -- switch --flake .#myhome

## Add the new zsh path to shells and make it user's shell
## LOGIN will break if not done
echo "/home/<ton_user>/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s "/home/<ton_user>/.nix-profile/bin/zsh" <ton_user>

'''