# AGENT – Home Manager

`home/` contains the Home Manager side of this repo.

## Main entry points
- `common.nix`: shared base profile for `gabriel`
- `laptop.nix`, `desktop.nix`: workstation variants built on top of `common.nix`
- `server.nix`: minimal server-side home profile reused by NixOS hosts

## Supporting folders
- `programs/`: reusable Home Manager modules
- `config/` and `dotfiles/`: static files deployed via Home Manager
- `../secrets/`: SOPS-encrypted data consumed by the home config

## Local rules
- Keep program modules focused and small.
- Keep shared logic in `common.nix` or dedicated reusable modules.
- Do not run `home-manager switch` without explicit approval.

## Tool removal boundary
- Do not wire tmux, kmux, tmuxp, tmuxinator, VS Code, or VSCodium into profiles,
  custom completions/plugins, launchers, or integrations.
- Keep unrelated shell helpers (including the `tx` tax calculator), Atuin,
  clipboard utilities, and WezTerm/Neovim integrations intact.
- Custom completion and OpenCode skill directories are deployed recursively;
  missing literal per-file imports do not make their contents unused.
