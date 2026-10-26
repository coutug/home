"""Non-activating removal/composition checks: python3 tests/test_cleanup.py.

Build only syntax tools and generated config files, never activation packages,
NixOS systems, secret installers, or services. No secret contents are read.
"""

import json
import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
REMOVED = re.compile(
    r"(?<![a-z0-9])(?:tmux(?:p|inator)?|kmux|vs[ -]?code|vscodium|codium|"
    r"code-insiders|visual[ -]?studio[ -]?code)(?![a-z0-9])",
    re.IGNORECASE,
)
REMOVED_COMMANDS = {"code", "code-insiders", "codium", "tmux", "tmuxp", "tmuxinator", "kmux"}


def run(*command):
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(f"{command!r} failed:\n{result.stderr}")
    return result.stdout


class SourceCleanup(unittest.TestCase):
    def test_runtime_sources_and_paths_have_no_removed_wiring(self):
        paths = run("git", "ls-files", "home", "hosts", "modules", "scripts", "flake.nix").splitlines()
        for name in paths:
            path = ROOT / name
            if not path.exists() or path.name == "AGENTS.md":
                continue
            with self.subTest(path=name):
                self.assertIsNone(REMOVED.search(name))
                self.assertIsNone(REMOVED.search(path.read_text()))

    def test_detector_covers_helpers_and_editor_names(self):
        for value in ("_tmuxinator", "tmux-resurrect", "tmuxp/kmux.yml", "vscode-extensions", "VSCodium"):
            self.assertIsNotNone(REMOVED.search(value))
        for value in ("opencode", "exit code", "tx", "wezterm", "clipboard-jh"):
            self.assertIsNone(REMOVED.search(value))


class ProfileCleanup(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        expression = r'''
          let
            flake = builtins.getFlake (builtins.getEnv "TEST_FLAKE");
            inherit (flake.homeConfigurations.laptop) pkgs;
            project = config: {
              packages = map pkgs.lib.getName config.home.packages;
              files = builtins.attrNames config.home.file;
              xdgFiles = builtins.attrNames config.xdg.configFile;
              generated = builtins.mapAttrs (_: file: file.text)
                (pkgs.lib.filterAttrs (_: file: file.text != null) config.home.file);
              aliases = config.programs.zsh.shellAliases;
              plugins = config.programs.zsh.oh-my-zsh.plugins;
              shell = toString config.home.file."./.zshrc".source;
              stateVersion = config.home.stateVersion;
              programs = builtins.listToAttrs (map (name: {
                inherit name;
                value = config.programs.${name}.enable;
              }) [ "zsh" "fzf" "zoxide" "bat" "htop" "home-manager"
                   "atuin" "neovim" "wezterm" "k9s" "tmux" "vscode" ]);
            };
            homes = builtins.attrValues flake.homeConfigurations;
            hosts = builtins.attrValues flake.nixosConfigurations;
            shellFiles = map (home: home.config.home.file."./.zshrc".source) homes
              ++ map (host: host.config.home-manager.users.gabriel.home.file."./.zshrc".source) hosts;
            terminalFiles = map (home: home.config.xdg.configFile."wezterm/wezterm.lua".source) homes;
            syntaxCheck = pkgs.runCommand "cleanup-config-syntax" {
              nativeBuildInputs = [ pkgs.zsh pkgs.lua ];
            } ''
              for file in ${pkgs.lib.escapeShellArgs shellFiles}; do
                zsh -n "$file"
              done
              for file in ${pkgs.lib.escapeShellArgs terminalFiles}; do
                luac -p "$file"
              done
              touch "$out"
            '';
          in {
            syntaxCheck = syntaxCheck.drvPath;
            homes = builtins.mapAttrs (_: home: (project home.config) // {
              activation = home.activationPackage.drvPath;
              terminal = toString home.config.xdg.configFile."wezterm/wezterm.lua".source;
              atuin = home.config.programs.atuin.settings;
            }) flake.homeConfigurations;
            hosts = builtins.mapAttrs (_: host: {
              home = project host.config.home-manager.users.gabriel;
              toplevel = host.config.system.build.toplevel.drvPath;
              stateVersion = host.config.system.stateVersion;
              role = host.config.services.k0s.role;
              tailscale = host.config.services.tailscale.enable;
            }) flake.nixosConfigurations;
          }
        '''
        result = subprocess.run(
            ["nix", "eval", "--impure", "--json", "--expr", expression],
            cwd=ROOT, env={**os.environ, "TEST_FLAKE": str(ROOT)},
            capture_output=True, text=True,
        )
        if result.returncode:
            raise RuntimeError(result.stderr)
        cls.data = json.loads(result.stdout)

    def profiles(self):
        yield from self.data["homes"].items()
        for name, host in self.data["hosts"].items():
            yield name, host["home"]

    def test_removed_tools_absent_from_all_five_profiles(self):
        for name, profile in self.profiles():
            with self.subTest(profile=name):
                self.assertFalse(profile["programs"]["tmux"])
                self.assertFalse(profile["programs"]["vscode"])
                for package in profile["packages"]:
                    self.assertNotIn(package, REMOVED_COMMANDS)
                    self.assertIsNone(REMOVED.search(package))
                for value in profile["files"] + profile["xdgFiles"] + profile["plugins"]:
                    self.assertIsNone(REMOVED.search(value))
                for alias, command in profile["aliases"].items():
                    self.assertNotIn(alias, REMOVED_COMMANDS)
                    self.assertIsNone(REMOVED.search(command))
                    self.assertNotIn(command.split()[0], REMOVED_COMMANDS)
                for target, text in profile["generated"].items():
                    self.assertIsNone(REMOVED.search(text), target)

    def test_surviving_composition(self):
        self.assertEqual(set(self.data["homes"]), {"laptop", "desktop"})
        self.assertEqual(set(self.data["hosts"]), {"nixos-mini1", "nixos-mini2", "nixos-mini3"})
        shared = {"zsh", "fzf", "zoxide", "bat", "htop", "home-manager"}
        for name, profile in self.profiles():
            with self.subTest(profile=name):
                for program in shared:
                    self.assertTrue(profile["programs"][program], program)
                self.assertIn(".p10k.zsh", profile["files"])
        for name, home in self.data["homes"].items():
            with self.subTest(profile=name):
                self.assertTrue(home["activation"].endswith(".drv"))
                self.assertEqual(home["stateVersion"], "25.05")
                self.assertIn("tx", home["plugins"])
                self.assertIn("yy", home["plugins"])
                for program in ("atuin", "neovim", "wezterm", "k9s"):
                    self.assertTrue(home["programs"][program], program)
                for package in ("clipboard-jh", "kubie", "kubectl", "agent-orchestrator"):
                    self.assertIn(package, home["packages"])
                self.assertEqual(home["aliases"]["nv"], "nvim")
                self.assertEqual(home["aliases"]["kc"], "kubie ctx")
                self.assertTrue(home["atuin"]["auto_sync"])
                self.assertEqual(home["atuin"]["sync_frequency"], "20m")
                for file in ("opencode/skills", "opencode/agents", "k9s/aliases.yaml", "nvim"):
                    self.assertIn(file, home["xdgFiles"])
        self.assertIn("hypr/hyprland.lua", self.data["homes"]["laptop"]["xdgFiles"])
        self.assertNotIn("hypr/hyprland.lua", self.data["homes"]["desktop"]["xdgFiles"])
        self.assertIn("containers/systemd/vllm.container", self.data["homes"]["desktop"]["xdgFiles"])
        for name, host in self.data["hosts"].items():
            with self.subTest(host=name):
                self.assertTrue(host["toplevel"].endswith(".drv"))
                self.assertEqual(host["stateVersion"], "25.11")
                self.assertEqual(host["home"]["stateVersion"], "25.11")
                self.assertEqual(host["role"], "controller+worker" if name == "nixos-mini2" else "worker")
                self.assertTrue(host["tailscale"])

    def test_generated_config_syntax_and_contents(self):
        shells = {profile["shell"] for _, profile in self.profiles()}
        terminals = {home["terminal"] for home in self.data["homes"].values()}
        run("nix", "build", "--no-link", f"{self.data['syntaxCheck']}^*")
        for path in sorted(shells | terminals):
            with self.subTest(path=path):
                self.assertIsNone(REMOVED.search(Path(path).read_text()))


if __name__ == "__main__":
    unittest.main(verbosity=2)
