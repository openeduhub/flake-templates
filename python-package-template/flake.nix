{
  description = "A Python package defined as a Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    {
      # provide the library and application each as an overlay
      overlays = import ./overlays.nix {
        inherit (nixpkgs) lib;
        nix-filter = self.inputs.nix-filter.lib;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        # add the python package to our nixpkgs
        pkgs =
          nixpkgs.legacyPackages.${system}.extend self.outputs.overlays.python-lib;
      in
      {
        # the packages that we can build
        packages = rec {
          inherit (pkgs.python3Packages) my-python-package;
          default = my-python-package;
        };
        # the development environment
        devShells.default = pkgs.callPackage ./shell.nix { };
      }
    );
}
