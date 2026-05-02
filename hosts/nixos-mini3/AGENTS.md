# AGENT – nixos-mini3

`hosts/nixos-mini3` defines a new mini host cloned from `nixos-mini1`.

## Host-specific facts
- NixOS `25.11`
- static IPv4 on `enp4s0`
- single-disk layout is defined in `disk-config.nix`
- hardware metadata will be generated later into `hardware-configuration.nix`

## k0s role
- k0s is installed, but the worker is not joined to the cluster yet
- the join token and age recipient will be added later
- when they arrive, wire `secrets/k0s/token-mini3.yaml` and re-enable `services.k0s`

## Deployment notes
- `nixos-anywhere` should use `hosts/nixos-mini3/disk-config.nix`
- `hardware-configuration.nix` will be generated later

## Network notes
- worker/overlay ports remain aligned with the mini worker profile

Do not run rebuild or deployment commands without explicit approval.
