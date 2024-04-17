{
  description = "A Python application defined as a Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
        # add both the standalone application and the python package to our
        # nixpkgs
        pkgs =
          (nixpkgs.legacyPackages.${system}.extend self.outputs.overlays.default).extend
            self.outputs.overlays.python-lib;
      in
      {
        # the packages that we can build
        packages = {
          inherit (pkgs) my-python-package;
          default = pkgs.my-python-package;
          docker = pkgs.callPackage ./docker.nix { };
        };
        # the development environment
        devShells.default = pkgs.callPackage ./shell.nix { };
      }
    );
}
