{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=cyan";
    };
    autocd = true;
    syntaxHighlighting.enable = true;
    completionInit = ''
      autoload -Uz compinit
      compinit
      zmodload zsh/complist

      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' menu select
    '';

    plugins = [
      {
        name = "zsh-powerlevel10k";
        src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
        file = "powerlevel10k.zsh-theme";
      }
    ];

    oh-my-zsh = {
      enable = true;
      # theme = "powerlevel10k/powerlevel10k";
      plugins = [
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
        "kmux"
        "sudo"
        "systemd"
        "tx"
        "terraform"
        "yy"
      ];
      custom = "$HOME/.zsh/custom/";
    };

    shellAliases = {
      ll = "eza -la --git";
      gs = "git status -sb";

      src = "source \"$HOME/.zshrc\"";
      mk = "minikube";
      yn = "yay --noconfirm";
      yc = "yay -Yc; yay -Sc";
      y = "yay";
      kc = "kubie ctx";
      vpn = "sudo openvpn \"$HOME/sync/Travail/ovpn/dor-gw1-coutug-laptop.ovpn\"";
      watch = "watch -c";

      nv = "nvim";
      pkgls = "pacman -Qq | fzf --preview 'pacman -Qil {}' --layout=reverse --bind 'enter:execute(pacman -Qil {} | less)'";
      ld = "lazydocker";
      lg = "lazygit";
      cat = "bat";
      kb = "kustomize build";
      oc = "opencode";

      ollama = "docker exec -it ollama ollama";

      kval = "kubeconform -summary -schema-location default -schema-location \"https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json\"";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        [[ -r "${config.home.homeDirectory}/.p10k.zsh" ]] && source "${config.home.homeDirectory}/.p10k.zsh"
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

        repo() {
          local base="$HOME/sync/Travail/Repo"
          local choice
          choice=$(printf '%s\n' "$base"/*(/:t) | fzf) || return
          code "$base/$choice"
        }
      '')
    ];
  };

  home.file.".p10k.zsh".source = ../dotfiles/p10k.zsh;
  home.file.".zsh/custom" = {
    source = ../config/omz-custom;
    recursive = true;
  };
}
