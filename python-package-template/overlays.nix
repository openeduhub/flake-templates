# overlays are the main way of providing the built python package to other nix
# projects.
{ lib, nix-filter }:
rec {
  default = python-lib;
  # TODO; change this to the actual package name
  python-lib = my-python-package;
  
  # make the python package available in all python versions
  my-python-package = (
    final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (python-final: python-prev: {
          # TODO; change this to the actual package name
          my-python-package = python-final.callPackage ./python-lib.nix { inherit nix-filter; };
        })
      ];
    }
  );
}
