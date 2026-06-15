{
  description = "Stephen's NixOS configuration — Verstappen";

  inputs = {
    # Pin nixpkgs to the current stable NixOS release.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS hardware tweaks (NVIDIA, etc.)
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "stephen";
      hostname = "verstappen";
    in
    {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username hostname; };

        modules = [
          ./hosts/${hostname}/configuration.nix
          ./hosts/${hostname}/hardware-configuration.nix

          # Common NixOS modules
          ./modules/desktop.nix
          ./modules/nvidia.nix
          ./modules/gaming.nix
          ./modules/dev.nix
          ./modules/ollama.nix

          # Home Manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs username; };
            home-manager.users.${username} = import ./home/${username}.nix;
            # Keep a backup of any conflicting files HM tries to manage
            home-manager.backupFileExtension = "hm-backup";
          }
        ];
      };

      # Convenience: `nix fmt` to format everything
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
