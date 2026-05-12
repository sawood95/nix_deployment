{
  description = "Stephen's NixOS configuration — Sagan";

  inputs = {
    # Pin nixpkgs to unstable for latest packages (claude-code, codex, etc.)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS hardware tweaks (NVIDIA, etc.)
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "stephen";
      hostname = "sagan";
    in
    {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username hostname; };

        modules = [
          ./hosts/${hostname}/configuration.nix
          ./hosts/${hostname}/hardware-configuration.nix

          # Common NixOS modules
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
