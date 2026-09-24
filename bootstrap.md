# Host bootstrap guide

`scripts/bootstrap-host` prepares SOPS data and then invokes `nixos-anywhere` for one mini host. Run it from the repository checkout on the NixOS installer environment; the script resolves and enters the repository root.

## Warning

The final step applies the selected host's `disk-config.nix` through `nixos-anywhere`. It can repartition and format the configured disks, permanently destroying their data. Verify the host, target IP, and disk identifiers before confirming installation.

## Prerequisites

- Ethernet connected and DHCP reservation configured for target host.
- SSH access to `root@<target-ip>` with target root password available.
- SSH identity file for the target available locally.
- Repository clone has a clean worktree and correct branch.
- `git`, `sops`, `ssh-to-age`, and `nix` are available.
- Review target host's `disk-config.nix` and confirm all declared disk IDs match target hardware.

## Run

```bash
scripts/bootstrap-host nixos-mini1 192.168.0.11 ~/.ssh/server_id_ed25519
scripts/bootstrap-host nixos-mini2 192.168.0.12 ~/.ssh/server_id_ed25519
scripts/bootstrap-host nixos-mini3 192.168.0.13 ~/.ssh/server_id_ed25519
```

Arguments are `<hostname> <target-ip> <identity-file>`. The script runs from repository root after resolving it with Git.

## Script flow

1. Creates, or reuses after confirmation, `secrets/hosts/<hostname>/ssh_host_ed25519_key.yaml`.
2. Extracts host age recipient and adds it to `secrets/k0s/.sops.yaml` and `secrets/users/.sops.yaml` after confirmation.
3. Runs `sops updatekeys` for user secrets and, when applicable, host k0s token secret.
4. Decrypts host SSH key into a temporary `--extra-files` directory. Temporary directory is removed when script exits.
5. Prompts before invoking `nixos-anywhere`, which generates `hosts/<hostname>/hardware-configuration.nix` with `nixos-generate-config`.

Before final confirmation, inspect `git diff`, confirm every changed secret remains encrypted, then commit and push recipient and secret changes. Never copy decrypted keys or auth values into repository files.

## Post-installation

After installation completes, confirm target boots, expected SSH host key is presented, and generated `hardware-configuration.nix` is present. Review resulting Git changes before committing. Do not run rebuild or deployment commands without explicit approval.
