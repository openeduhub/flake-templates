# this is where we define the python package and all of its dependencies.
{
  nix-filter,
  buildPythonPackage,
  pytestCheckHook,
  # example python packages
  numpy,
  pandas,
}:
buildPythonPackage {
  pname = "my-python-package";
  version = "0.1.0";
  
  # only include files that are related to the package.
  # this will prevent unnecessary rebuilds
  src = nix-filter {
    root = ./.;
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

  # the python packages we use
  propagatedBuildInputs = [
    numpy
    pandas
  ];
  
  # if test through pytest are included, uncomment the following.
  # this section is also where you would add additional test dependencies, such
  # as hypothesis.
  # nativeCheckInputs = [
  #   pytestCheckHook
  # ];
}
