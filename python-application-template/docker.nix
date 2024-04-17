# turn our python application into an automatically layered docker image
{
  dockerTools,
  # TODO: change this to the actual application / executable name
  my-python-package,
  cacert,
}:
dockerTools.buildLayeredImage {
  name = my-python-package.pname;
  tag = "latest";
  config.Cmd = [
    "${my-python-package}/bin/my-python-package"
  ];
  # uncomment if the container needs access to ssl certificates, e.g. for
  # fetching resources from https domains
  # config.Env = [ "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt" ];
}
