{
  description = "A Python package defined as a Nix Flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      projectDir = self;
      # import the packages from nixpkgs
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      # the python version we are using
      python = pkgs.python310;

      ### create the python installation for the package
      python-packages-build = py-pkgs:
        with py-pkgs; [pandas
                       numpy
                       # <add more packages here>
                       
                       # dependencies from PyPi, generated through nix-template
                       # (pkgs.callPackage
                       #   ./pkgs/<package name>.nix
                       #   {inherit buildPythonPackage <package dependencies>;})
                      ];
      python-build = python.withPackages python-packages-build;

      ### create the python installation for development
      # the development installation contains all build packages,
      # plus some additional ones we do not need to include in production.
      python-packages-devel = py-pkgs:
        with py-pkgs; [ipython
                       jupyter
                       black
                      ] ++ (python-packages-build py-pkgs);
      python-devel = python.withPackages python-packages-devel;

      ### create the python package
      python-package = python-build.pkgs.buildPythonPackage {
        pname = "my-python-package";
        version = "0.1.0";
        src = projectDir;
        propagatedBuildInputs = [python-build];
      };

    in rec {
      # the packages that we can build
      packages.${system} = rec {
        my-python-package = python-package;
        default = my-python-package;
      };
      # the development environment
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          # the development installation of python
          python-devel
          # non-python packages
          pkgs.nodePackages.pyright
          # for automatically generating nix expressions, e.g. from PyPi
          pkgs.nix-template
          # nix lsp
          pkgs.rnix-lsp
        ];
      };
    };
}
