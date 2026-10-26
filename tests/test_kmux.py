"""Run with python3 -m unittest discover -s tests -p 'test_kmux.py' -v.

Each invocation uses a disposable Zsh and HOME. PATH contains only find/grep;
all Kubernetes, tmux and FZF commands are mocks. No cluster access is possible.
"""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


PLUGIN = (
    Path(__file__).resolve().parents[1]
    / "home/config/omz-custom/plugins/kmux/kmux.plugin.zsh"
)
ZSH = shutil.which("zsh")
RUNNER = r'''
kubie() { print -r -- unexpected-kubie >> "$CALLS"; return 99; }
tmux() { print -r -- unexpected-tmux >> "$CALLS"; return 99; }
k9s() { print -r -- unexpected-k9s >> "$CALLS"; return 99; }
tmuxp() {
  print -r -- "tmuxp:$#:$1:$2:$session_name" >> "$CALLS"
  return "$TMUXP_STATUS"
}
fzf() {
  local line
  print -r -- fzf >> "$CALLS"
  while IFS= read -r line; do
    print -r -- "$line" >> "$CHOICES"
  done
  print -rn -- "$FZF_OUTPUT"
  return "$FZF_STATUS"
}
[[ "$MISSING_DEPENDENCY" == yes ]] && unfunction kubie
source "$PLUGIN"
kmux
print -r -- "result:$?"
if [[ "$REPEAT_EMPTY" == yes ]]; then
  # Second call must not reuse arrays from the first successful call.
  function find() { return 0; }
  kmux
  print -r -- "repeat-result:$?"
fi
[[ "$session_name" == original ]] || print -r -- leaked-session-name
(( ${+KUBECONFIG_DIR} || ${+config} || ${+context_line} || ${+context} ||
   ${+current_context} || ${+kubeconfigs} || ${+contexts} )) && print -r -- leaked-variable
print -r -- shell-survived
'''


@unittest.skipUnless(ZSH, "zsh is required")
class KmuxTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kmux-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.configs = self.home / ".kube/kubeconfig"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("find", "grep"):
            executable = shutil.which(name)
            self.assertIsNotNone(executable, f"{name} is required")
            (self.bin / name).symlink_to(executable)
        self.calls = self.root / "calls"
        self.choices = self.root / "choices"

    def config(self, text="current-context: test-context\n", name="test config.yaml"):
        self.configs.mkdir(parents=True, exist_ok=True)
        (self.configs / name).write_text(text)

    def run_kmux(self, expected=1, **overrides):
        env = {
            "HOME": str(self.home),
            "PATH": str(self.bin),
            "PLUGIN": str(PLUGIN),
            "CALLS": str(self.calls),
            "CHOICES": str(self.choices),
            "FZF_OUTPUT": "test-context\n",
            "FZF_STATUS": "0",
            "TMUXP_STATUS": "0",
            "session_name": "original",
            "LC_ALL": "C",
            **overrides,
        }
        result = subprocess.run(
            [ZSH, "-f", "-c", RUNNER], env=env, text=True,
            capture_output=True, timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"result:{expected}\n", result.stdout)
        self.assertIn("shell-survived\n", result.stdout)
        self.assertNotIn("leaked-", result.stdout)
        calls = self.calls.read_text().splitlines() if self.calls.exists() else []
        self.assertFalse(any(call.startswith("unexpected-") for call in calls))
        return result, calls

    def test_missing_dependency(self):
        result, calls = self.run_kmux(MISSING_DEPENDENCY="yes")
        self.assertIn("missing required commands", result.stderr)
        self.assertEqual(calls, [])

    def test_absent_directory(self):
        result, calls = self.run_kmux()
        self.assertIn("does not exist", result.stderr)
        self.assertEqual(calls, [])

    def test_empty_directory(self):
        self.configs.mkdir(parents=True)
        result, calls = self.run_kmux()
        self.assertIn("no kubeconfig files", result.stderr)
        self.assertEqual(calls, [])

    def test_missing_kubeconfig(self):
        self.config("ignored", "notes.txt")
        result, calls = self.run_kmux()
        self.assertIn("no kubeconfig files", result.stderr)
        self.assertEqual(calls, [])

    def test_dangling_kubeconfig_symlink(self):
        self.configs.mkdir(parents=True)
        (self.configs / "missing.yaml").symlink_to(self.root / "absent.yaml")
        result, calls = self.run_kmux()
        self.assertIn("no kubeconfig files", result.stderr)
        self.assertEqual(calls, [])

    def test_empty_context_list(self):
        for contents in ("", "clusters: []\n", "current-context:  \t\n"):
            with self.subTest(contents=contents):
                self.config(contents)
                result, calls = self.run_kmux()
                self.assertIn("no contexts found", result.stderr)
                self.assertEqual(calls, [])

    def test_fzf_cancellation_or_failure(self):
        self.config()
        for status in ("1", "2", "130"):
            for output in ("", "test-context\n"):
                with self.subTest(status=status, output=output):
                    self.calls.unlink(missing_ok=True)
                    _, calls = self.run_kmux(FZF_STATUS=status, FZF_OUTPUT=output)
                    self.assertEqual(calls, ["fzf"])

    def test_empty_fzf_selection(self):
        self.config()
        _, calls = self.run_kmux(FZF_OUTPUT="\n")
        self.assertEqual(calls, ["fzf"])

    def test_success_with_spaces_and_symlink(self):
        self.configs.mkdir(parents=True)
        target = self.root / "fixture config.yml"
        target.write_text("  current-context:  team context  \n")
        (self.configs / "linked config.yml").symlink_to(target)
        _, calls = self.run_kmux(expected=0, FZF_OUTPUT="team context\n")
        self.assertEqual(calls, ["fzf", "tmuxp:2:load:kmux:team context"])
        self.assertEqual(self.choices.read_text(), "team context\n")

    def test_tmuxp_failure_propagates(self):
        self.config()
        _, calls = self.run_kmux(expected=7, TMUXP_STATUS="7")
        self.assertEqual(calls, ["fzf", "tmuxp:2:load:kmux:test-context"])

    def test_repeated_call_does_not_reuse_contexts(self):
        self.config()
        result, calls = self.run_kmux(expected=0, REPEAT_EMPTY="yes")
        self.assertIn("repeat-result:1\n", result.stdout)
        self.assertEqual(calls, ["fzf", "tmuxp:2:load:kmux:test-context"])


if __name__ == "__main__":
    unittest.main()
