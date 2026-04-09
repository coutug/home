# AGENT – encrypted secrets

`secrets/` stores SOPS-encrypted credentials referenced by `home/common.nix` and future NixOS hosts. The directory includes:

- `codex/config.toml`: encrypted Codex configuration that carries the real `INCIDENT_IO_API_KEY`.
- `opencode/opencode.json`: declarative OpenCode configuration (agents, MCPs, permissions, templates) that `home/common.nix` deploys to `~/.config/opencode/opencode.json`.
- `opencode/dashboard-builder/*.md`: prompt files for the dashboard orchestration workflow, deployed under `~/.config/opencode/prompts/dashboard-builder/`.
- `kubeconfig/*.yml`: encrypted kubeconfig files exposed under `~/.kube/kubeconfig/<name>.yml` via the `sops-nix` home module.

Policy:

- Never commit plaintext credentials. Use `sops --encrypt --age <pubkey> ...` before adding new secrets.
- When editing an existing file under `secrets/`, prefer the in-place SOPS flow: `sops decrypt <file>.json -i`, edit the file, then `sops encrypt <file>.json -i`.
- Update `home/AGENTS.md` (and any host `AGENTS.md` that touches these secrets) when exposing a new file so the dependency graph stays documented.
- Do not reveal the ages or keys themselves in this repo; the configuration assumes they are already available on the target system.
