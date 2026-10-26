{
  config,
  pkgs,
  lib,
  opencode,
  ...
}:
{
  imports = [
    ./zsh-core.nix
    ./home-manager.nix
  ];

  # Arch aliases remain workstation preferences, not server defaults.
  home.packages = [
    opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
  ]
  ++ (with pkgs; [
    bc
    docker-client
    fzf
    lazydocker
    lazygit
    minikube
    pacman
    terraform
    yay
    yazi
  ]);
  programs.neovim.enable = true;

  programs.zsh = {
    oh-my-zsh = {
      custom = "${config.home.homeDirectory}/.zsh/custom";
      plugins = lib.mkMerge [
        (lib.mkOrder 100 [
          "archlinux"
          "docker"
        ])
        (lib.mkOrder 130 [ "fzf" ])
        (lib.mkOrder 190 [ "minikube" ])
        (lib.mkOrder 230 [
          "tx"
          "terraform"
          "yy"
        ])
      ];
    };

    shellAliases = {
      mk = "minikube";
      y = "yay";
      yn = "yay --noconfirm";
      yc = "yay -Yc; yay -Sc";
      nv = "nvim";
      nv-dev = "NVIM_APPNAME=nvim-dev nvim";
      ld = "lazydocker";
      lg = "lazygit";
      oc = "opencode";
      pkgls = "pacman -Qq | fzf --preview 'pacman -Qil {}' --layout=reverse --bind 'enter:execute(pacman -Qil {} | less)'";
      nix-desktop = "home-manager switch --flake .#desktop -b back";
      nix-laptop = "home-manager switch --flake .#laptop -b back";
      nix-mini1 = "nix run nixpkgs#nixos-rebuild -- switch --flake .#nixos-mini1 --target-host root@nixos-mini1 --build-host root@nixos-mini1";
      nix-mini2 = "nix run nixpkgs#nixos-rebuild -- switch --flake .#nixos-mini2 --target-host root@nixos-mini2 --build-host root@nixos-mini2";
      nix-mini3 = "nix run nixpkgs#nixos-rebuild -- switch --flake .#nixos-mini3 --target-host root@nixos-mini3 --build-host root@nixos-mini3";
    };
  };

  home.file = {
    ".zsh/custom/completions" = {
      source = ../config/omz-custom/completions;
      recursive = true;
    };
    ".zsh/custom/plugins/tx" = {
      source = ../config/omz-custom/plugins/tx;
      recursive = true;
    };
    ".zsh/custom/plugins/yy" = {
      source = ../config/omz-custom/plugins/yy;
      recursive = true;
    };
  };
}
