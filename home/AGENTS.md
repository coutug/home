# AGENT – Home Manager configuration

Home Manager controls everything under `home/`. `common.nix` defines the shared profile for `gabriel`, reuses `sops-nix`, and imports a set of modular program files that live in `home/programs`. `laptop.nix` and `desktop.nix` call `common.nix` and layer in any extras (the desktop adds the `reaper*` packages). `server.nix` is a skeleton profile that can be re-used when a NixOS host needs a matching user configuration.

Supporting folders:

- `home/programs`: reusable Home Manager modules for tools like `atuin`, `bat`, `fzf`, `htop`, `k9s`, `obs-studio`, `wezterm`, `zoxide`, and shell tooling. Each file returns attributes imported by `common.nix`.
- `home/config` & `home/dotfiles`: static configuration fragments (VS Code settings, tmux config, custom Oh My Zsh plugins, etc.) exposed via `home.file`/`xdg.configFile` so they stay under version control.
- `secrets/`: referenced through `sops-nix` in `common.nix` to deploy kubeconfigs, Codex, and OpenCode data under `~/.kube` and `~/.codex`.

Workflow reminders:

- The `home/` tree is the **only** place to run `home-manager switch` in this repository. Do **not** execute `home-manager switch --flake .#...` (or any other `home-manager` command) without explicit approval.
- Follow the module conventions established here: keep program files small, reuse helpers, and keep `home/common.nix` as the shared base.
