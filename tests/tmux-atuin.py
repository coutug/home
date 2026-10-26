"""Generated-config tests; all runtime state and clipboard tools are disposable."""

import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib


def run(args, *, env, check=True, input=None):
    result = subprocess.run(
        args, env=env, input=input, text=True, capture_output=True,
        check=False, timeout=30,
    )
    if check and result.returncode:
        raise AssertionError(f"{args}: {result.returncode}\n{result.stdout}\n{result.stderr}")
    return result


data = json.loads(Path(sys.argv[1]).read_text())
tmux_config = Path(data["tmuxConfig"]).read_text()
atuin_config = Path(data["atuinConfig"]).read_text()
settings = tomllib.loads(atuin_config)
assert settings["auto_sync"] is False
assert settings["theme"]["name"] == "marine"
assert settings["style"] == "compact"
assert settings["invert"] and settings["enter_accept"]
assert settings["daemon"]["enabled"]
assert "@plugin " not in tmux_config
assert "@clipboard@" not in tmux_config
for plugin in [data["sensible"], *data["plugins"]]:
    assert Path(plugin).is_file(), plugin
    assert tmux_config.count(f"run-shell {plugin}\n") == 1, plugin
assert tmux_config.index(data["sensible"]) < tmux_config.index("# Remap prefix")
assert tmux_config.index(data["plugins"][-1]) < tmux_config.index("# Remap prefix")
clipboard = re.search(r"set -g @override_copy_command '([^']+)'", tmux_config)[1]
for key in ["Enter", "MouseDragEnd1Pane"]:
    assert f"{key} send-keys -X copy-pipe-and-cancel '{clipboard}'" in tmux_config
copy_script = Path(clipboard).read_text()
assert data["wlCopy"] in copy_script and data["xclip"] in copy_script

with tempfile.TemporaryDirectory(prefix="tmux-atuin-") as temp:
    root = Path(temp)
    home = root / "home"
    home.mkdir()
    # Do not inherit production Atuin paths, credentials, displays, or tmux socket.
    env = {
        "PATH": data["path"], "HOME": str(home), "TERM": "xterm-256color",
        "XDG_CONFIG_HOME": str(home / ".config"),
        "XDG_DATA_HOME": str(home / ".local/share"),
        "XDG_CACHE_HOME": str(home / ".cache"),
        "XDG_STATE_HOME": str(home / ".local/state"),
        "XDG_RUNTIME_DIR": str(root), "ATUIN_LOG": "warn",
        "ATUIN_SESSION": "00000000000040008000000000000001",
    }
    atuin_dir = home / ".config/atuin"
    atuin_dir.mkdir(parents=True)
    (atuin_dir / "config.toml").write_text(atuin_config)
    for key, expected in [("auto_sync", "false"), ("theme.name", "marine")]:
        result = run(["atuin", "config", "get", "--resolved", key], env=env)
        assert result.stdout.strip().strip('"') == expected, result
    # Empty synthetic database only; this command loads the selected built-in theme.
    result = run(["atuin", "search", "--limit", "1", "synthetic-regression"], env=env, check=False)
    assert result.returncode == 1, result  # No matches in the empty test database.
    assert not result.stdout.strip(), result
    assert not result.stderr.strip(), result.stderr

    # Replace only the declared backend executables, never touch a real clipboard.
    for backend in ["wayland", "x11"]:
        mock = root / backend
        mock.write_text(f'#!/bin/sh\nprintf "{backend}:%s\\n" "$*" > "$CLIPBOARD_TEST_LOG"\ncat >> "$CLIPBOARD_TEST_LOG"\n')
        if backend == "x11":
            with mock.open("a") as script:
                script.write('printf "output that must not reach tmux"\n')
        mock.chmod(0o755)
    mock_copy = root / "copy"
    mock_copy.write_text(copy_script.replace(data["wlCopy"], str(root / "wayland"))
                         .replace(data["xclip"], str(root / "x11")))
    mock_copy.chmod(0o755)
    cases = [
        ({"WAYLAND_DISPLAY": "wayland-test"}, "wayland:\n"),
        ({"DISPLAY": ":test"}, "x11:-selection clipboard -in\n"),
        ({"WAYLAND_DISPLAY": "wayland-test", "DISPLAY": ":test"}, "wayland:\n"),
    ]
    log = root / "clipboard-log"
    for display, expected in cases:
        result = run([str(mock_copy)], env=env | display | {"CLIPBOARD_TEST_LOG": str(log)}, input="synthetic clipboard\n")
        assert not result.stdout, result
        assert log.read_text() == expected + "synthetic clipboard\n"
    result = run([str(mock_copy)], env=env, check=False, input="synthetic clipboard\n")
    assert result.returncode == 1 and "no Wayland or X11 display" in result.stderr
    assert not result.stdout

    if "--config-only" in sys.argv:
        print("Generated config, profile wiring, Atuin, and clipboard tests passed; run output/run-tests for tmux runtime checks")
        sys.exit(0)

    tmux_dir = home / ".config/tmux"
    tmux_dir.mkdir()
    (tmux_dir / "tmux.conf").write_text(tmux_config)
    config = home / ".tmux.conf"
    config.write_text(data["legacyConfig"].replace("/home/test", str(home)))
    tmux = ["tmux", "-S", str(root / "tmux.sock")]
    try:
        result = run(tmux + ["-f", str(config), "new-session", "-d", "-s", "regression",
                            shutil.which("sleep", path=env["PATH"]) + " 300"], env=env)
        assert not result.stderr, result.stderr

        def option(name):
            return run(tmux + ["show-options", "-gqv", name], env=env).stdout.strip()

        assert option("prefix2") == "C-a"
        assert option("mouse") == "on"
        assert option("renumber-windows") == "on"
        assert option("@override_copy_command") == clipboard
        theme_format = option("@themepack-status-left-area-left-format")
        assert theme_format, run(tmux + ["capture-pane", "-p"], env=env).stdout
        assert "cyan" in option("status-style")
        assert option("@resurrect-save-script-path")
        for table, key, command in [
            ("prefix", "C-a", "send-prefix -2"),
            ("prefix", "h", "split-window -v"),
            ("prefix", "v", "copy-mode"),
            ("prefix", "r", "source-file"),
            ("prefix", "F", "/tmux-fzf/main.sh"),
            ("prefix", "y", "/yank/scripts/copy_line.sh"),
            ("root", "M-Left", "select-pane -L"),
            ("root", "M-Right", "select-pane -R"),
            ("root", "M-Up", "select-pane -U"),
            ("root", "M-Down", "select-pane -D"),
            ("root", "C-s", "synchronize-panes"),
            ("copy-mode-vi", "Enter", clipboard),
            ("copy-mode-vi", "MouseDragEnd1Pane", clipboard),
        ]:
            result = run(tmux + ["list-keys", "-T", table], env=env)
            binding = next((line for line in result.stdout.splitlines()
                            if re.search(rf"-T {re.escape(table)}\s+{re.escape(key)}\s+", line)), "")
            assert command in binding, (table, key, binding)
        # Reload must remain safe and keep bindings after plugin initialization.
        result = run(tmux + ["source-file", str(config)], env=env)
        assert not result.stderr, result.stderr
        assert option("prefix2") == "C-a"
    finally:
        run(tmux + ["kill-server"], env=env, check=False)

print("tmux/Atuin generated config, plugin wiring, bindings, clipboard, and local history tests passed")
