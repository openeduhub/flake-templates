{
  description = "A Python package defined as a Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # enable if unfree packages are required
          config.allowUnfree = false;
        };
        nix-filter = self.inputs.nix-filter.lib;
        python = pkgs.python310;

        ### list of python packages required to build / run the application
        python-packages-build = py-pkgs:
          with py-pkgs; [ pandas
                          numpy
                          # <add more packages here>
                          
                          /*
                          dependencies from PyPi, generated through nix-init
                          (pkgs.callPackage
                            ./pkgs/<package name>.nix
                            {inherit buildPythonPackage <package deps>;})
                         */
                        ];
        
        ### list of python packages to include in the development environment
        # the development installation contains all build packages,
        # plus some additional ones we do not need to include in production.
        python-packages-devel = py-pkgs:
          with py-pkgs; [ ipython
                          jupyter
                          black
                        ]
          ++ (python-packages-build py-pkgs);

        ### create the python package
        python-app = python.pkgs.buildPythonApplication {
          pname = "my-python-app";
          version = "0.1.0";
          /*
          only include files that are related to the application
          this will prevent unnecessary rebuilds
          */
          src = nix-filter {
            root = self;
            include = [
              # folders
              "src"
              "my-python-app"
              "test"
              # files
              ./setup.py
              ./requirements.txt
            ];
            exclude = [ (nix-filter.matchExt "pyc") ];
          };
          propagatedBuildInputs = (python-packages-build python.pkgs);
        };
        
        ### build the docker image
        docker-img = pkgs.dockerTools.buildImage {
          name = python-app.pname;
          tag = python-app.version;
          config = {
            # name of command modified in setup.py
            Cmd = ["${python-app}/bin/my-python-app"];
            # uncomment if the container needs access to ssl certificates
            # Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
          };
        };

      in rec {
        # the packages that we can build
        packages = rec {
          my-python-app = python-app;
          docker = docker-img;
          default = my-python-app;
        };
        # the development environment
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # the development installation of python
            (python.withPackages python-packages-devel)
            # python LSP server
            pkgs.nodePackages.pyright
            # for automatically generating nix expressions, e.g. from PyPi
            pkgs.nix-template
            pkgs.nix-init
          ];
        };
      }
    );
}
