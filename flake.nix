{
  description = "Nix Flake Templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {inherit system;};
    in {
      templates = {
        python-package = {
          path = ./python-package-template;
          description = "A Python package defined as a Nix Flake";
        };
        python-application = {
          path = ./python-application-template;
          description = "A Python application defined as a Nix Flake";
        };
      };
      # the development environment
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [pkgs.rnix-lsp];
      };
    };
}
