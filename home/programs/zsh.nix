{ ... }:
{
  # Workstation entry point; servers deliberately do not import this composition.
  imports = [
    ./zsh-workstation.nix
    ./zsh-kubernetes.nix
  ];
}
