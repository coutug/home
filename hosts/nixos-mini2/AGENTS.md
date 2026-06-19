# AGENT – nixos-mini2

`hosts/nixos-mini2` defines the primary node of the mini NixOS cluster.

## Host-specific facts
- NixOS `26.05`
- DHCP on `enp4s0` with router-side reservation
- disk layout is defined in `disk-config.nix`
- hardware metadata is generated into `facter.json` via `nixos-facter`

## k0s role
- bootstrap controller + worker for the `k0s-mini` cluster

## Deployment notes
- `nixos-anywhere` must use `hosts/nixos-mini2/disk-config.nix`
- installation also regenerates `hosts/nixos-mini2/facter.json`
- this host keeps facter enabled and filters null CPU entries before evaluation

## Network notes
- controller ports exposed: `6443`, `8132`, `9443`, `2379`, `2380`
- worker/overlay ports exposed: `10250`, `4240`, `4244` TCP and `8472`, `6081` UDP
- Tailscale is enabled with auth key from `secrets/tailscale/mini2`; UDP `41641` is opened by `services.tailscale.openFirewall`.

Do not run rebuild or deployment commands without explicit approval.
