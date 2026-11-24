# Nix home & host configurations

Declarative Home Manager profiles, NixOS host definitions, and SOPS-encrypted secrets live in this repo and are wired through the root `flake.nix`.

## Layout
- `home/`: Home Manager configuration for `gabriel` (`common.nix`, `laptop.nix`, `desktop.nix`, `server.nix`, `programs/`, `config/`, `dotfiles/`)
- `hosts/`: NixOS hosts (`nixos-mini1`, `nixos-mini2`, `nixos-mini3`)
- `secrets/`: encrypted data consumed by the configs
- `modules/`: shared NixOS modules
- `result/`: build output; ignore it

## Workflows
- Refresh/verify inputs with `nix flake update`, `nix flake show`, and `nix flake check`
- Ask before running any `home-manager switch`, `nixos-rebuild`, or `nixos-anywhere` command
- Hosts use `disk-config.nix`; bootstrap generates `hardware-configuration.nix` with `nixos-generate-config`

### Update Engram

Home Manager pins the Linux x86_64 release binary and the OpenCode plugin to the
same Engram version in `home/programs/engram-version.json`. To update both hashes
and the version together, run:

```sh
python3 scripts/update-engram.py 3.7.2  # replace with the desired stable release
python3 tests/test_engram_update.py
nix flake check
nix build --no-link .#homeConfigurations.laptop.activationPackage .#homeConfigurations.desktop.activationPackage
```

Review the upstream release and generated diff before deploying. The script
downloads the release archive and plugin source to calculate their Nix hashes; it does not verify
signatures or activate anything. After an approved Home Manager activation,
restart any existing Engram HTTP server through its owner and compare
`engram version` with the version in `curl -fsS http://127.0.0.1:7437/health`.
Verify the actual executable selected by `command -v engram`; an older yay
installation may still take precedence in your shell. The MCP and plugin use
the Nix binary directly, unless `ENGRAM_BIN` overrides the plugin's default.
Remove stale overrides and revalidate OpenCode in a new session. Back up the
Engram data before upgrades, especially major releases.

## AGENTS guide
Read the nearest `AGENTS.md` before editing a subtree:
- `AGENTS.md`: repo-wide rules and baseline
- `home/AGENTS.md`: Home Manager conventions
- `hosts/nixos-mini1/AGENTS.md`: worker host specifics
- `hosts/nixos-mini2/AGENTS.md`: primary host specifics
- `hosts/nixos-mini3/AGENTS.md`: worker host specifics
- `secrets/AGENTS.md`: secret handling rules

## Notes
- Keep changes declarative and reproducible.
- Any new operational rule, module, workflow, or secret policy should be reflected in the relevant `AGENTS.md`.
- Profiles do not configure or install tmux/kmux, tmuxp/tmuxinator, VS Code, or VSCodium.
  This does not uninstall manually installed tools or remove unmanaged dotfiles.
- Run `python3 tests/test_cleanup.py` for removal and profile-composition regressions;
  see [testing.md](testing.md) for other non-activating checks.
