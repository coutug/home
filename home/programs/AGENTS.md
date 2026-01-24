# AGENT – Home Manager program modules

The `home/programs` directory hosts focused Home Manager modules that configure individual applications. Each `.nix` file typically declares `programs.<name>` settings, shell functions, or helper services and is imported from `home/common.nix`.

Patterns:

- Keep files short and tool-specific. For example, `zsh.nix` configures the shell, `wezterm.nix` wraps the GUI terminal with `nixGL`, and `obs-studio.nix` enables hardware acceleration via `nixGL` overlays.
- Use `lib.hm.dag` hooks when a program needs activation scripts (see how `home/common.nix` schedules the VS Code backup and extension sync).
- If a new program requires more than a small profile, consider moving shared helpers into a dedicated module and importing it from `home/common.nix`.

Avoid running `home-manager switch` while editing these files unless the change is approved; mention the intended command in the commit message or changelog so reviewers can validate before executing it.
