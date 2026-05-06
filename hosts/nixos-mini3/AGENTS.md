# AGENT – nixos-mini3

`hosts/nixos-mini3` defines a new mini host cloned from `nixos-mini1`.

## Host-specific facts
- NixOS `25.11`
- DHCP on `enp4s0` with router-side reservation
- single-disk layout is defined in `disk-config.nix`
- hardware metadata will be generated later into `hardware-configuration.nix`

## k0s role
- k0s is installed and configured as a worker
- the join token is stored at `secrets/k0s/token-mini3.yaml`
- it is deployed via `sops-nix` to `/etc/k0s/k0stoken` (`root:root`, `0400`)

## Deployment notes
- `nixos-anywhere` should use `hosts/nixos-mini3/disk-config.nix`
- `hardware-configuration.nix` will be generated later

## Network notes
- worker/overlay ports remain aligned with the mini worker profile

Do not run rebuild or deployment commands without explicit approval.
