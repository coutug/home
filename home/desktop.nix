{ ... }:
{
  imports = [
    ./common.nix
    ./programs/vllm.nix
    ./programs/wireplumber.nix
  ];
}
