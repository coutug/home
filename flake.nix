{
  description = "Nix + Home Manager configs for laptop, desktop, and nixos-mini";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
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
      url = "github:anomalyco/opencode?ref=v1.1.17";
    };
    oh-my-opencode = {
      url = "github:code-yeongyu/oh-my-opencode?ref=v3.0.0-beta.7";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixgl,
      sops-nix,
      opencode,
      oh-my-opencode,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nixgl.overlay ];
      };
      ohMyOpencode = pkgs.callPackage ./pkgs/oh-my-opencode { src = oh-my-opencode; };
    in
    {
      packages = {
        ${system} = {
          "oh-my-opencode" = ohMyOpencode;
        };
      };

      homeConfigurations = {
        laptop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit
              nixgl
              sops-nix
              opencode
              ohMyOpencode
              ;
          };
          modules = [
            ./home/laptop.nix
          ];
        };
        desktop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit
              nixgl
              sops-nix
              opencode
              ohMyOpencode
              ;
          };
          modules = [
            ./home/desktop.nix
          ];
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
