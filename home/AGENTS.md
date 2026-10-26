# AGENT – Home Manager

`home/` contains the Home Manager side of this repo.

## Main entry points
- `common.nix`: shared base profile for `gabriel`
- `laptop.nix`, `desktop.nix`: workstation variants built on top of `common.nix`
- `server.nix`: minimal server-side home profile reused by NixOS hosts

## Supporting folders
- `programs/`: reusable Home Manager modules
- `programs/zsh-core.nix`: shared shell behavior, prompt, safe aliases, and dependencies
- `programs/zsh.nix`: workstation entry point composing `zsh-workstation.nix` and
  `zsh-kubernetes.nix`; each layer owns its plugins and shell dependencies
- `programs/zsh-server.nix`: core-only server composition and server prompt flag;
  no Arch, Docker, desktop editor, or Kubernetes helper aliases/plugins
- `config/` and `dotfiles/`: static files deployed via Home Manager
- `../secrets/`: SOPS-encrypted data consumed by the home config

## Local rules
- Keep program modules focused and small.
- Keep shared logic in `common.nix` or dedicated reusable modules.
- Do not run `home-manager switch` without explicit approval.
- Keep surviving custom Zsh plugin paths stable.
  Workstation completions and custom plugins must not leak into server profiles.
- Shell layers declare local command dependencies. Arch package operations still
  require an Arch workstation; Docker requires a running daemon; Kubernetes/PVC
  helpers require authorized cluster/network access and node-side tools.
- The shared sudo plugin requires the host's privileged `sudo` wrapper. Never
  install an unprivileged Home Manager sudo binary that could shadow it.
- Run `nix eval --impure --json --file tests/zsh-layers.nix` from the repo root
  for shell composition/dependency regression checks (no activation or decryption).
- Run `nix build --impure --no-link --file tests/zsh-shell.nix` for generated
  shell syntax checks, executable dependency checks, and a disposable-home
  server shell smoke test, without activation.

## Tool removal boundary
- Do not wire tmux, kmux, tmuxp, tmuxinator, VS Code, or VSCodium into profiles,
  custom completions/plugins, launchers, or integrations.
- Keep unrelated shell helpers (including the `tx` tax calculator), Atuin,
  clipboard utilities, and WezTerm/Neovim integrations intact.
- Custom completion and OpenCode skill directories are deployed recursively;
  missing literal per-file imports do not make their contents unused.
- Run `python3 tests/test_cleanup.py` alongside shell-layer tests to ensure
  compositions do not reintroduce retired tools.
