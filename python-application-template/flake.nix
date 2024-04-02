{
  description = "A Python application defined as a Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      nix-filter = self.inputs.nix-filter.lib;

      ### create the python installation for the package
      python-packages-build = py-pkgs: with py-pkgs; [ numpy pandas ];

      ### create the python installation for development
      # the development installation contains all build packages,
      # plus some additional ones we do not need to include in production.
      python-packages-devel = py-pkgs:
        with py-pkgs;
        [ black ipython isort mypy pyflakes pylint pytest pytest-cov ]
        ++ (python-packages-build py-pkgs);

      ### the python package and application
      get-python-package = py-pkgs:
        py-pkgs.buildPythonPackage {
          pname = "my-python-package";
          version = "0.1.0";
          /* only include files that are related to the application.
                 this will prevent unnecessary rebuilds
          */
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

      get-python-app = py-pkgs:
        py-pkgs.toPythonApplication (get-python-package py-pkgs);

    in {
      # provide the library and application each as an overlay
      overlays = rec {
        default = app;
        app = (final: prev: {
          my-python-app = self.outputs.packages.${final.system}.default;
        });
        python-lib = (final: prev: {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (python-final: python-prev: {
              my-python-package = self.outputs.lib.default python-final;
            })
          ];
        });
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # use the default python3 version
        python = pkgs.python3;
        python-app = get-python-app python.pkgs;

        ### the docker image
        docker-img = pkgs.dockerTools.buildLayeredImage {
          name = python-app.pname;
          tag = python-app.version;
          config = {
            # name of command modified in setup.py
            Cmd = [ "${python-app}/bin/my-python-app" ];
            # uncomment if the container needs access to ssl certificates
            # Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
          };
        };
      in {
        # the packages that we can build
        packages = {
          default = python-app;
        } // (nixpkgs.lib.optionalAttrs
          # only build docker images on linux systems
          (system == "x86_64-linux" || system == "aarch64-linux") {
            docker = docker-img;
          });
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
      });
}
