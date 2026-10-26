# Run without activating either profile:
# nix build --impure --no-link --file tests/k9s-aliases.nix
let
  flake = builtins.getFlake (toString ../.);
  inherit (flake) homeConfigurations;
  inherit (homeConfigurations.laptop) pkgs;
  python = pkgs.python3.withPackages (packages: [ packages.pyyaml ]);
in
pkgs.runCommand "k9s-aliases-regression"
  {
    nativeBuildInputs = [ python ];
    laptopAliases = homeConfigurations.laptop.config.xdg.configFile."k9s/aliases.yaml".source;
    desktopAliases = homeConfigurations.desktop.config.xdg.configFile."k9s/aliases.yaml".source;
  }
  ''
    python <<'PY'
    import os
    from pathlib import Path

    import yaml

    expected = {
        "dp": "deployments",
        "sec": "v1/secrets",
        "jo": "jobs",
        "cr": "clusterroles",
        "crb": "clusterrolebindings",
        "ro": "roles",
        "rb": "rolebindings",
        "np": "networkpolicies",
    }
    for profile in ("laptop", "desktop"):
        source = Path(os.environ[f"{profile}Aliases"])
        document = yaml.safe_load(source.read_text())
        assert document == {"aliases": expected}, (
            f"{profile}: expected exactly one aliases wrapper and all eight aliases; "
            f"got {document!r}"
        )
        assert document["aliases"]["dp"] == "deployments"
        assert "aliases" not in document["aliases"]
        print(f"{profile}: aliases.dp is deployments; all eight aliases preserved")
    PY
    touch "$out"
  ''
