# AGENT – encrypted secrets

`secrets/` stores SOPS-encrypted credentials referenced by `home/common.nix` and future NixOS hosts. The directory includes:

- `codex/config.toml`: encrypted Codex configuration that carries the real `INCIDENT_IO_API_KEY`.
- `opencode/opencode.json`: declarative OpenCode configuration (plugin OAuth, templates) that `home/common.nix` deploys to `~/.config/opencode/opencode.json`.
- `kubeconfig/*.yml`: encrypted kubeconfig files exposed under `~/.kube/kubeconfig/<name>.yml` via the `sops-nix` home module.

Policy:

- Never commit plaintext credentials. Use `sops --encrypt --age <pubkey> ...` before adding new secrets.
- Update `home/AGENTS.md` (and any host `AGENTS.md` that touches these secrets) when exposing a new file so the dependency graph stays documented.
- Do not reveal the ages or keys themselves in this repo; the configuration assumes they are already available on the target system.
