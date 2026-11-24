import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/update-engram.py"
spec = importlib.util.spec_from_file_location("update_engram", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class EngramUpdateTest(unittest.TestCase):
    def test_updates_both_hashes_for_one_version(self):
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / "engram-version.json"
            with patch.object(module, "prefetch", side_effect=["binary-hash", "plugin-hash"]) as fetch:
                module.update("3.7.3", manifest)
            self.assertEqual(json.loads(manifest.read_text()), {
                "version": "3.7.3", "binaryHash": "binary-hash", "pluginHash": "plugin-hash"
            })
            self.assertIn("/v3.7.3/engram_3.7.3_linux_amd64.tar.gz", fetch.call_args_list[0].args[0])
            self.assertIn("/v3.7.3/plugin/opencode/engram.ts", fetch.call_args_list[1].args[0])

    def test_failed_second_download_preserves_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / "engram-version.json"
            manifest.write_text("original")
            with patch.object(module, "prefetch", side_effect=["binary-hash", subprocess.CalledProcessError(1, "nix")]):
                with self.assertRaises(subprocess.CalledProcessError):
                    module.update("3.7.3", manifest)
            self.assertEqual(manifest.read_text(), "original")

    def test_invalid_version_is_rejected_before_fetch(self):
        with patch.object(module, "prefetch") as fetch:
            with self.assertRaises(ValueError):
                module.update("../main")
            fetch.assert_not_called()


if __name__ == "__main__":
    unittest.main()
