{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Dependencies of shared aliases, Oh My Zsh plugins, and the existing prompt.
  # sudo must come from the host's privileged wrapper, never a home package.
  home.packages = with pkgs; [
    coreutils
    eza
    git
    gnugrep
    gnused
    less
    procps
    systemd
  ];

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
      # Orders preserve the workstation plugin sequence across composed layers.
      plugins = lib.mkMerge [
        (lib.mkOrder 160 [ "git" ])
        (lib.mkOrder 220 [
          "sudo"
          "systemd"
        ])
      ];
    };

    shellAliases = {
      ll = "eza -la --git";
      src = "source \"$HOME/.zshrc\"";
      watch = "watch -c";
    };

    initContent = lib.mkOrder 500 ''
      [[ -r "${config.home.homeDirectory}/.p10k.zsh" ]] && source "${config.home.homeDirectory}/.p10k.zsh"
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

    '';
  };

  home.file.".p10k.zsh".source = ../dotfiles/p10k.zsh;
}
