{
  description = "IT's JOINTLY Nix Flake Templates";

  outputs = { self, ... }: {
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
  };
}
