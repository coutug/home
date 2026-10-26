# Run from the repository root:
# nix eval --impure --json --file tests/zsh-layers.nix
let
  flake = builtins.getFlake (toString ../.);
  inherit (flake.inputs.nixpkgs) lib;
  pkgs = import flake.inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  isolated =
    module:
    (flake.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit (flake.inputs) opencode; };
      modules = [
        module
        {
          home.username = "shell-test";
          home.homeDirectory = "/home/shell-test";
          home.stateVersion = "25.11";
        }
      ];
    }).config;
  core = isolated ../home/programs/zsh-core.nix;
  workstation = isolated ../home/programs/zsh-workstation.nix;
  kubernetes = isolated ../home/programs/zsh-kubernetes.nix;
  server = isolated ../home/programs/zsh-server.nix;
  homes = lib.mapAttrs (_: value: value.config) flake.homeConfigurations;
  hosts = lib.mapAttrs (_: value: value.config) flake.nixosConfigurations;
  servers = lib.mapAttrs (_: value: value.home-manager.users.gabriel) hosts;
  plugins = config: config.programs.zsh.oh-my-zsh.plugins;
  corePlugins = [
    "git"
    "sudo"
    "systemd"
  ];
  workstationPlugins = [
    "archlinux"
    "docker"
    "fluxcd"
    "fzf"
    "get-clusters"
    "get-nodes"
    "git"
    "helm"
    "kubectl"
    "minikube"
    "pvc-usage"
    "sudo"
    "systemd"
    "tx"
    "terraform"
    "yy"
  ];
  coreAliases = {
    ll = "eza -la --git";
    src = "source \"$HOME/.zshrc\"";
    watch = "watch -c";
  };
  workstationAliases = coreAliases // {
    mk = "minikube";
    y = "yay";
    yn = "yay --noconfirm";
    yc = "yay -Yc; yay -Sc";
    kc = "kubie ctx";
    nv = "nvim";
    nv-dev = "NVIM_APPNAME=nvim-dev nvim";
    ld = "lazydocker";
    lg = "lazygit";
    kb = "kustomize build";
    oc = "opencode";
    pkgls = "pacman -Qq | fzf --preview 'pacman -Qil {}' --layout=reverse --bind 'enter:execute(pacman -Qil {} | less)'";
    kval = "kubeconform -summary -schema-location default -schema-location \"https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json\"";
    nix-desktop = "home-manager switch --flake .#desktop -b back";
    nix-laptop = "home-manager switch --flake .#laptop -b back";
    nix-mini1 = "nix run nixpkgs#nixos-rebuild -- switch --flake .#nixos-mini1 --target-host root@nixos-mini1 --build-host root@nixos-mini1";
    nix-mini2 = "nix run nixpkgs#nixos-rebuild -- switch --flake .#nixos-mini2 --target-host root@nixos-mini2 --build-host root@nixos-mini2";
    nix-mini3 = "nix run nixpkgs#nixos-rebuild -- switch --flake .#nixos-mini3 --target-host root@nixos-mini3 --build-host root@nixos-mini3";
  };
  hasPackages =
    config: names: lib.all (name: lib.elem name (map lib.getName config.home.packages)) names;
  corePackages = [
    "coreutils"
    "eza"
    "git"
    "gnugrep"
    "gnused"
    "less"
    "procps"
    "systemd"
  ];
  workstationPackages = [
    "bc"
    "docker"
    "fzf"
    "lazydocker"
    "lazygit"
    "minikube"
    "pacman"
    "terraform"
    "yay"
    "yazi"
    "neovim"
  ];
  kubernetesPackages = [
    "bash-interactive"
    "curl"
    "fluxcd"
    "fzf"
    "jq"
    "kubeconform"
    "kubectl"
    "kubernetes-helm"
    "kubie"
    "kustomize"
    "openssh"
  ];
  customPlugins =
    config:
    builtins.filter (name: lib.hasPrefix ".zsh/custom/plugins/" name) (
      builtins.attrNames config.home.file
    );
  kubernetesFiles = map (name: ".zsh/custom/plugins/${name}") [
    "get-clusters"
    "get-nodes"
    "pvc-usage"
  ];
  test = name: condition: {
    inherit name;
    value = if condition then "passed" else throw "Zsh layer regression: ${name}";
  };
  checks = builtins.listToAttrs (
    [
      (test "core-is-minimal" (
        plugins core == corePlugins
        && core.programs.zsh.shellAliases == coreAliases
        && customPlugins core == [ ]
      ))
      (test "core-dependencies" (hasPackages core corePackages && !(hasPackages core [ "sudo" ])))
      (test "workstation-isolated" (
        plugins workstation == [
          "archlinux"
          "docker"
          "fzf"
          "git"
          "minikube"
          "sudo"
          "systemd"
          "tx"
          "terraform"
          "yy"
        ]
        && !(workstation.programs.zsh.shellAliases ? kc)
      ))
      (test "workstation-dependencies" (
        hasPackages workstation (corePackages ++ workstationPackages)
        && workstation.programs.home-manager.enable
        && lib.elem flake.inputs.opencode.packages.x86_64-linux.default workstation.home.packages
      ))
      (test "kubernetes-isolated" (
        plugins kubernetes == [
          "fluxcd"
          "get-clusters"
          "get-nodes"
          "git"
          "helm"
          "kubectl"
          "pvc-usage"
          "sudo"
          "systemd"
        ]
        && !(kubernetes.programs.zsh.shellAliases ? y)
        && customPlugins kubernetes == kubernetesFiles
      ))
      (test "kubernetes-dependencies" (hasPackages kubernetes (corePackages ++ kubernetesPackages)))
      (test "server-isolated" (
        plugins server == corePlugins
        && server.programs.zsh.shellAliases == coreAliases
        && customPlugins server == [ ]
        && server.home.sessionVariables.SERVER_PROMPT == 1
      ))
    ]
    ++ lib.mapAttrsToList (
      name: config:
      test "home-${name}" (
        plugins config == workstationPlugins
        && config.programs.zsh.shellAliases == workstationAliases
        && hasPackages config (corePackages ++ workstationPackages ++ kubernetesPackages)
        && config.home.stateVersion == "25.05"
        && toString config.home.file.".p10k.zsh".source == "${flake.outPath}/home/dotfiles/p10k.zsh"
      )
    ) homes
    ++ lib.mapAttrsToList (
      name: config:
      test "server-${name}" (
        plugins config == corePlugins
        && config.programs.zsh.shellAliases == coreAliases
        && customPlugins config == [ ]
        && !(config.home.file ? ".zsh/custom/completions")
        && hasPackages config corePackages
        && !(lib.any (
          package:
          lib.elem (lib.getName package) [
            "yay"
            "sudo"
            "pacman"
            "docker"
            "minikube"
            "lazygit"
            "kubectl"
            "terraform"
            "yazi"
          ]
        ) config.home.packages)
        && config.home.sessionVariables.SERVER_PROMPT == 1
        && config.home.stateVersion == "25.11"
        && toString config.home.file.".p10k.zsh".source == "${flake.outPath}/home/dotfiles/p10k.zsh"
        && hosts.${name}.system.stateVersion == "25.11"
        && hosts.${name}.security.sudo.enable
      )
    ) servers
  );
in
{
  inherit checks;
  # Force complete output derivation evaluation, not merely individual options.
  homeActivation = lib.mapAttrs (_: value: value.activationPackage.drvPath) flake.homeConfigurations;
  nixosToplevel = lib.mapAttrs (
    _: value: value.config.system.build.toplevel.drvPath
  ) flake.nixosConfigurations;
}
