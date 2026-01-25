{
  description = "Nix + Home Manager configs for laptop, desktop, and nixos-mini";

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
      url = "github:anomalyco/opencode?ref=v1.1.34";
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
        nixos-mini = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./hosts/nixos-mini/configuration.nix
            k0s-nix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit sops-nix k0s-nix; };
              home-manager.users.gabriel = ./home/server.nix;
            }
            { hardware.facter.reportPath = ./hosts/nixos-mini/facter.json; }
          ];
          specialArgs = { inherit k0s-nix sops-nix; };
        };
      };
    };
}
