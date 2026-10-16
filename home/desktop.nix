{
  pkgs,
  ...
}:
{
  imports = [
    ./common.nix
    ./programs/vllm.nix
  ];
  home = {
    packages = with pkgs; [
      solaar
    ];
  };
}
