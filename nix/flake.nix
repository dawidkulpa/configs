{
  description = "NixOS & nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fish-tide = {
      url = "github:IlanCosman/tide";
      flake = false;
    };

    fish-pj = {
      url = "github:oh-my-fish/plugin-pj";
      flake = false;
    };

    tldr-pages = {
      url = "github:tldr-pages/tldr";
      flake = false;
    };

    skyrocket-spoon = {
      url = "github:clo4/SkyRocket.spoon";
      flake = false;
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    agenix.url = "github:ryantm/agenix";
  };

  outputs = inputs @ {
    nixpkgs,
    nixos-wsl,
    home-manager,
    darwin,
    flake-utils,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    homebrew-bundle,
    agenix,
    ...
  }: let
    home-manager-buggy = path: {
      home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;
        users.buggy = path;
        extraSpecialArgs = {
          inherit inputs;
        };
      };
    };

    home-manager-buggy-s = path: {
      home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;
        users.buggy = path;
        extraSpecialArgs = {
          inherit inputs;
        };
      };
    };
  in
    {
      darwinConfigurations = {
        macbookIntel = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            home-manager.darwinModules.default
            (home-manager-buggy ./systems/macbookIntel/home.nix)
            ./systems/macbookIntel/host.nix
            agenix.darwinModules.default
          ];
          specialArgs = {
            inherit inputs;
          };
        };
      };

      nixosConfigurations = {
        nixosPC = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.default
            (home-manager-buggy ./systems/pc/home.nix)
            ./systems/pc/host.nix
            agenix.nixosModules.default
          ];
          specialArgs = {
            inherit inputs;
          };
        };

        nixosWSL = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.default
            nixos-wsl.nixosModules.default
            (home-manager-buggy ./systems/wsl/home.nix)
            ./systems/wsl/host.nix
            agenix.nixosModules.default
          ];
          specialArgs = {
            inherit inputs;
          };
        };

        nixosServer = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.default
            (home-manager-buggy-s ./systems/server/home.nix)
            ./systems/server/host.nix
            agenix.nixosModules.default
          ];
          specialArgs = {
            inherit inputs;
          };
        };
      };

      templates = {
        untracked-flake = {
          path = ./templates/untracked-flake;
          description = "Flake to be used with my `mkflake` shell function";
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      formatter = pkgs.alejandra;
      devShell = pkgs.mkShell {
        packages = with pkgs; [
          nil
          alejandra
        ];
      };
    });
}
