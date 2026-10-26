"""Run with python3 tests/test_kubeconfig_permissions.py; never activate SOPS."""

import json
import os
from pathlib import Path
import shlex
import stat
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
PROFILES = ("laptop", "desktop")


class KubeconfigPermissions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix="kubeconfig-permissions-")
        cls.addClassCleanup(cls.temporary.cleanup)
        # Spaces and a quote exercise shell escaping of the configured home.
        cls.home = Path(cls.temporary.name) / "test user's home"
        expression = r'''
          let
            flake = builtins.getFlake (builtins.getEnv "TEST_FLAKE");
            project = profile:
              let
                home = flake.homeConfigurations.${profile};
                config = home.config;
                sandbox = home.extendModules {
                  modules = [ ({ lib, ... }: {
                    home.homeDirectory = lib.mkForce (builtins.getEnv "TEST_HOME");
                  }) ];
                };
              in {
                secrets = builtins.mapAttrs (_: secret: {
                  inherit (secret) mode path;
                }) (home.pkgs.lib.filterAttrs
                  (name: _: home.pkgs.lib.hasPrefix "kubeconfig/" name)
                  config.sops.secrets);
                hook = config.home.activation.ensureKubeconfigDirectory;
                order = map (entry: entry.name)
                  (flake.inputs.home-manager.lib.hm.dag.topoSort config.home.activation).result;
                script = sandbox.config.home.activation.ensureKubeconfigDirectory.data;
              };
          in {
            profiles = builtins.listToAttrs (map (name: {
              inherit name; value = project name;
            }) [ "laptop" "desktop" ]);
            helper = "${flake.inputs.home-manager.outPath}/lib/bash/home-manager.sh";
            coreutils = flake.homeConfigurations.laptop.pkgs.coreutils.outPath;
          }
        '''
        result = subprocess.run(
            ["nix", "eval", "--impure", "--json", "--expr", expression],
            cwd=ROOT,
            env={**os.environ, "TEST_FLAKE": str(ROOT), "TEST_HOME": str(cls.home)},
            capture_output=True,
            text=True,
        )
        if result.returncode:
            raise RuntimeError(result.stderr)
        cls.evaluated = json.loads(result.stdout)
        # Build only the hook's executable, not any secret installer or service.
        subprocess.run(
            ["nix", "build", "--no-link", cls.evaluated["coreutils"]], check=True
        )

    def run_hook(self, profile, dry_run=False):
        environment = dict(os.environ)
        environment.pop("DRY_RUN", None)
        if dry_run:
            environment["DRY_RUN"] = "1"
        script = (
            "set -euo pipefail\n"
            f"source {shlex.quote(self.evaluated['helper'])}\n"
            + self.evaluated["profiles"][profile]["script"]
        )
        subprocess.run(
            ["bash", "-c", script], env=environment, check=True,
            capture_output=True, text=True,
        )

    def test_secret_modes_and_actual_parent(self):
        expected = {
            f"kubeconfig/{p.name}" for p in (ROOT / "secrets/kubeconfig").iterdir()
        }
        self.assertTrue(expected)
        for profile in PROFILES:
            with self.subTest(profile=profile):
                secrets = self.evaluated["profiles"][profile]["secrets"]
                self.assertEqual(set(secrets), expected)
                for name, secret in secrets.items():
                    self.assertEqual(secret["mode"], "0600")
                    self.assertEqual(secret["path"], f"/home/gabriel/.kube/{name}")

    def test_activation_order(self):
        for profile in PROFILES:
            with self.subTest(profile=profile):
                config = self.evaluated["profiles"][profile]
                hook = config["hook"]
                self.assertIn("writeBoundary", hook["after"])
                self.assertIn("sops-nix", hook["before"])
                order = config["order"]
                self.assertLess(
                    order.index("writeBoundary"), order.index("ensureKubeconfigDirectory")
                )
                self.assertLess(
                    order.index("ensureKubeconfigDirectory"), order.index("sops-nix")
                )

    def test_directory_creation_migration_idempotence_and_dry_run(self):
        directory = self.home / ".kube/kubeconfig"
        for profile in PROFILES:
            with self.subTest(profile=profile):
                self.run_hook(profile, dry_run=True)
                self.assertFalse(directory.exists())
                self.run_hook(profile)
                self.assertEqual(stat.S_IMODE(directory.stat().st_mode), 0o700)
                # Existing installs may have a public directory and SOPS symlinks.
                target = self.home / "synthetic-target"
                target.touch(mode=0o600)
                link = directory / "synthetic.yml"
                link.symlink_to(target)
                directory.chmod(0o755)
                self.run_hook(profile, dry_run=True)
                self.assertEqual(stat.S_IMODE(directory.stat().st_mode), 0o755)
                for _ in range(2):
                    self.run_hook(profile)
                    self.assertEqual(stat.S_IMODE(directory.stat().st_mode), 0o700)
                    self.assertTrue(link.is_symlink())
                    self.assertEqual(link.resolve(), target)
                    self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)
                link.unlink()
                target.unlink()
                directory.rmdir()


if __name__ == "__main__":
    unittest.main(verbosity=2)
