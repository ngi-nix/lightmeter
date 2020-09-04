{ buildGoModule, buildGoPackage }:
{ src, version }:

buildGoModule {
  pname = "lightmeter";
  inherit version src;

  GIT_COMMIT = src.rev or "";
  GIT_BRANCH = src.ref or "";

  # require the inconsistent vendors in go.mod
  # buildGoPackage errors out with missing dependency
  patches = [ ./consistent-vendoring.patch ];

  postConfigure = ''
    export PACKAGE_VERSION="$src/version"
    export APP_VERSION=$(cat VERSION.txt)

    buildFlags+=( "-ldflags" "-X $PACKAGE_VERSION.Commit=$GIT_COMMIT" "-X $PACKAGE_VERSION.TagOrBranch=$GIT_BRANCH" "-X $PACKAGE_VERSION.Version=$APP_VERSION")
  '';

  vendorSha256 = "0lkg20lxrklpn8h2vi8p4zy78fwp1qmiwmqwqpwvpajyrxqmfr7i";

  postInstall = ''
    ln -s $out/bin/controlcenter $out/bin/lightmeter
  '';
}
