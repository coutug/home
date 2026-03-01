# Add host

Comment out the flake.nix line using the facter.json file (while it is not generated)

 ```
 nix run github:nix-community/nixos-anywhere -- \
  --flake .#nixos-mini2 \
  --target-host root@192.168.0.64 \
  -i ~/.ssh/server_id_ed25519 \
  --generate-hardware-config nixos-facter hosts/nixos-mini2/facter.json
```