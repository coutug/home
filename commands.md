# New server

From USB installation of NixOS:

- connect Ethernet;
- set the DHCP reservation on the router;
- run the one-shot bootstrap script from this repo.

## One-shot bootstrap

The bootstrap script generates and stores the SSH host key as a SOPS secret,
updates SOPS recipients, prepares `--extra-files`, and runs `nixos-anywhere`.

**Warning:** the script creates or updates encrypted secrets and SOPS recipient rules. Review and push those changes before confirming the final `nixos-anywhere` step.

```bash
scripts/bootstrap-host nixos-mini1 192.168.0.11 ~/.ssh/server_id_ed25519
scripts/bootstrap-host nixos-mini2 192.168.0.12 ~/.ssh/server_id_ed25519
scripts/bootstrap-host nixos-mini3 192.168.0.13 ~/.ssh/server_id_ed25519
```

See [bootstrap guide](bootstrap.md) for the full process.
