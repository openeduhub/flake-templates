# this is where we define the development environment, which includes all of
# the package's dependencies and some additional packages we might want to
# include.
{
  mkShell,
  python3,
  pyright,
  nix-template,
  nix-init,
  nix-tree,
  dive,
}:
mkShell {
  packages = [
    (python3.withPackages (
      py-pkgs:
      with py-pkgs;
      [
        # additional python packages we want to include in the development
        # environment
        black
        ipython
        jupyter
        isort
        mypy
        pyflakes
        pylint
        pytest
        pytest-cov
      ]
      # TODO: change the name to the actual package name
      ++ py-pkgs.my-python-package.propagatedBuildInputs
    ))
    # python LSP
    pyright
    # tools for working with nix / docker
    nix-template
    nix-init
    nix-tree
    dive
  ];
}
