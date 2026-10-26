{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./zsh-core.nix ];

  # Includes local dependencies of inventory and PVC helpers. Remote
  # cluster access and node-side sudo/du/df remain runtime prerequisites.
  home.packages = with pkgs; [
    bash
    curl
    fluxcd
    fzf
    jq
    kubeconform
    kubectl
    kubernetes-helm
    kubie
    kustomize
    openssh
  ];

  programs.zsh = {
    oh-my-zsh = {
      custom = "${config.home.homeDirectory}/.zsh/custom";
      plugins = lib.mkMerge [
        (lib.mkOrder 120 [ "fluxcd" ])
        (lib.mkOrder 140 [
          "get-clusters"
          "get-nodes"
        ])
        (lib.mkOrder 170 [
          "helm"
          "kubectl"
        ])
        (lib.mkOrder 200 [
          "pvc-usage"
        ])
      ];
    };
    shellAliases = {
      kc = "kubie ctx";
      kb = "kustomize build";
      kval = "kubeconform -summary -schema-location default -schema-location \"https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json\"";
    };
  };

  home.file =
    lib.genAttrs
      (map (name: ".zsh/custom/plugins/${name}") [
        "get-clusters"
        "get-nodes"
        "pvc-usage"
      ])
      (path: {
        source = ../config/omz-custom/plugins + "/${builtins.baseNameOf path}";
        recursive = true;
      });
}
