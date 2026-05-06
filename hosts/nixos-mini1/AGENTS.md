# AGENT – nixos-mini1

`hosts/nixos-mini1` defines the worker node of the mini NixOS cluster.

## Host-specific facts
- NixOS `25.11`
- DHCP on `enp6s0` with router-side reservation
- disk layout is defined in `disk-config.nix`
- hardware metadata is generated into `facter.json` via `nixos-facter`

## k0s role
- runs as a `k0s` worker
- join token is stored at `secrets/k0s/token-mini1.yaml`
- deployed via `sops-nix` to `/etc/k0s/k0stoken` (`root:root`, `0400`)

## Deployment notes
- `nixos-anywhere` must use `hosts/nixos-mini1/disk-config.nix`
- installation also regenerates `hosts/nixos-mini1/facter.json`

## Network notes
- worker/overlay ports exposed: `10250`, `4240`, `4244` TCP and `8472`, `6081` UDP

Do not run rebuild or deployment commands without explicit approval.
