{
  description = "A Python package defined as a Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      nix-filter = self.inputs.nix-filter.lib;

      ### create the python installation for the package
      python-packages-build = py-pkgs:
        with py-pkgs; [
          numpy
          pandas
          # <add more packages here>
        ];

      ### create the python installation for development
      # the development installation contains all build packages,
      # plus some additional ones we do not need to include in production.
      python-packages-devel = py-pkgs:
        with py-pkgs; [
          black
          ipython
          isort
          mypy
          pyflakes
          pylint
          pytest
          pytest-cov
          # library stubs for mypy
          pandas-stubs
        ]
        ++ (python-packages-build py-pkgs);

      ### create the python package
      get-python-package = py-pkgs: py-pkgs.buildPythonPackage {
        pname = "my-python-package";
        version = "0.1.0";
        /* only include files that are related to the application.
               this will prevent unnecessary rebuilds */
        src = nix-filter {
          root = self;
          include = [
            # folders
            "src"
            "my_python_package"
            "test"
            # files
            ./setup.py
            ./requirements.txt
          ];
          exclude = [ (nix-filter.matchExt "pyc") ];
        };
        propagatedBuildInputs = (python-packages-build py-pkgs);
      };
    in
    {
      lib = {
        default = get-python-package;
      };
      # define an overlay to the library to nixpkgs
      overlays.default = (final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (python-final: python-prev: {
            my-python-package = self.outputs.lib.default python-final;
          })
        ];
      });
    } //
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python3;
        in
        {
          # the packages that we can build
          packages = {
            default = self.outputs.lib.default python.pkgs;
          };
          # the development environment
          devShells.default = pkgs.mkShell {
            buildInputs = [
              # the development installation of python
              (python.withPackages python-packages-devel)
              # python lsp server
              pkgs.nodePackages.pyright
              # for automatically generating nix expressions, e.g. from PyPi
              pkgs.nix-template
              pkgs.nix-init
            ];
          };
        }
      );
}
