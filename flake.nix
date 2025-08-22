{
  description = "Nix + Home Manager configs for laptop, desktop, and nixos-mini";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nixgl.overlay ];
      };
    in {
      homeConfigurations = {
        laptop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/laptop.nix ];
        };
        desktop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/desktop.nix ];
        };
      };

      nixosConfigurations = {
        nixos-mini = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nixos-mini/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.myuser = import ./home/server.nix;
            }
          ];
        };
      };
    };
}
