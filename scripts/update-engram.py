#!/usr/bin/env python3
"""Update the pinned Engram release and both Nix hashes together."""

import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "home/programs/engram-version.json"


def prefetch(url):
    result = subprocess.run(
        ["nix", "store", "prefetch-file", "--json", url],
        check=True,
        capture_output=True,
        text=True,
    )
    value = json.loads(result.stdout)["hash"]
    if not isinstance(value, str) or not re.fullmatch(r"sha256-[A-Za-z0-9+/]{43}=", value):
        raise ValueError("Nix returned an invalid SHA-256 hash")
    return value


def update(version, manifest=MANIFEST):
    if not re.fullmatch(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)", version):
        raise ValueError("Version must be a stable release number, for example 3.7.2")

    base = "https://github.com/Gentleman-Programming/engram"
    binary = f"{base}/releases/download/v{version}/engram_{version}_linux_amd64.tar.gz"
    plugin = f"https://raw.githubusercontent.com/Gentleman-Programming/engram/v{version}/plugin/opencode/engram.ts"
    release = {"version": version, "binaryHash": prefetch(binary), "pluginHash": prefetch(plugin)}

    # Leave the existing pin untouched if either fetch or validation fails.
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=manifest.parent, delete=False) as output:
        temporary = Path(output.name)
        try:
            json.dump(release, output, indent=2)
            output.write("\n")
            output.flush()
        except BaseException:
            temporary.unlink(missing_ok=True)
            raise
    try:
        temporary.replace(manifest)
    finally:
        temporary.unlink(missing_ok=True)
    print(f"Pinned Engram {version}; review changes and run nix flake check and Home Manager builds.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python3 scripts/update-engram.py <stable-version>")
    try:
        update(sys.argv[1])
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(f"Engram update failed: {error}")
