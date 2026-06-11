# AGENT – encrypted secrets

`secrets/` contains SOPS-encrypted data consumed by Home Manager and NixOS hosts.

## Rules
- Never commit plaintext credentials.
- Use SOPS for creation and edits.
- Prefer in-place SOPS workflows for existing files.
- Do not expose age keys, private material, or decrypted content in the repo.

## Notes
- Secrets in this tree are deployed declaratively from the configs.
- Tailscale auth keys live under `secrets/tailscale/*.env` as SOPS-encrypted dotenv files with a `key` entry.
- If a new secret becomes part of the system, update the relevant `AGENTS.md`.
