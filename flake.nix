{
  description = "Nix + Home Manager configs for laptop, desktop, and NixOS mini hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode?ref=v1.14.29";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    k0s-nix = {
      url = "github:johbo/k0s-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixgl,
      sops-nix,
      opencode,
      disko,
      k0s-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nixgl.overlay ];
      };
    in
    {
      homeConfigurations = {
        laptop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit nixgl sops-nix opencode; };
          modules = [
            ./home/laptop.nix
          ];
        };
        desktop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit nixgl sops-nix opencode; };
          modules = [
            ./home/desktop.nix
          ];
        };
      };

      packages = {
        ${system} = {
          inherit (k0s-nix.packages.${system}) k0s;
        };
      };

      nixosConfigurations = {
        nixos-mini1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./hosts/nixos-mini1/configuration.nix
            ./hosts/nixos-mini1/hardware-configuration.nix
            k0s-nix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit sops-nix k0s-nix; };
              home-manager.users.gabriel = ./home/server.nix;
            }
          ];
          specialArgs = { inherit k0s-nix sops-nix; };
        };

        nixos-mini2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./hosts/nixos-mini2/configuration.nix
            ./hosts/nixos-mini2/hardware-configuration.nix
            k0s-nix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit sops-nix k0s-nix; };
              home-manager.users.gabriel = ./home/server.nix;
            }
          ];
          specialArgs = { inherit k0s-nix sops-nix; };
        };

        nixos-mini3 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./hosts/nixos-mini3/configuration.nix
          ]
          ++ nixpkgs.lib.optionals (builtins.pathExists ./hosts/nixos-mini3/hardware-configuration.nix) [
            ./hosts/nixos-mini3/hardware-configuration.nix
          ]
          ++ [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit sops-nix k0s-nix; };
              home-manager.users.gabriel = ./home/server.nix;
            }
          ];
          specialArgs = { inherit k0s-nix sops-nix; };
        };
      };
    };
}
