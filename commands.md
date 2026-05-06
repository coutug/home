# New server

From USB installation of nixOS
- add network by connecting with Ethernet

Create age key from ssh-to-age and create k0s token from k0s controller
ssh-to-age to create private key from ssh key
age-keygen to get public key and add it to .sops.yaml to encrypt the k0s token

# Running nixos-anywhere

- hardware-configuration.nix is generated from the command *[ref](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md#8-prepare-hardware-configuration)*

nix run github:nix-community/nixos-anywhere -- --flake .#nixos-mini1 --target-host root@192.168.0.11 -i ~/.ssh/server_id_ed25519 --generate-hardware-config nixos-generate-config ./hosts/nixos-mini1/hardware-configuration.nix
nix run github:nix-community/nixos-anywhere -- --flake .#nixos-mini2 --target-host root@192.168.0.12 -i ~/.ssh/server_id_ed25519 --generate-hardware-config nixos-generate-config ./hosts/nixos-mini2/hardware-configuration.nix
SSHPASS=root-password nix run github:nix-community/nixos-anywhere -- --flake .#nixos-mini3 --target-host root@192.168.0.13 -i ~/.ssh/server_id_ed25519 --generate-hardware-config nixos-generate-config ./hosts/nixos-mini3/hardware-configuration.nix --env-password
