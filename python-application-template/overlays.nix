# overlays are the main way of providing the built python package / application
# to other nix projects.
{ lib, nix-filter }:
rec {
  # TODO: change this to the actual package name
  default = my-python-package;

  # make the python package available in all python versions
  python-lib = (
    final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (python-final: python-prev: {
          # TODO; change this to the actual package name
          my-python-package = python-final.callPackage ./python-lib.nix { inherit nix-filter; };
        })
      ];
    }
  );

  # add the standalone python application, without adding the python package
  my-python-package = (
    final: prev:
    let
      # because we are not adding the python package to the global python
      # environment, add it here locally
      py-pkgs = (final.extend python-lib).python3Packages;
    in
    {
      my-python-package = py-pkgs.callPackage ./package.nix {};
    }
  );
}
