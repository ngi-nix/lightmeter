{ buildGoModule, buildGoPackage }:
{ src, version }:

buildGoModule {
  pname = "lightmeter";
  inherit version src;

  # require the inconsistent vendors in go.mod
  # buildGoPackage errors out with missing dependency
  patches = [ ./consistent-vendoring.patch ];

  buildFlagsArray =
    let
      GIT_COMMIT = src.rev or "";
      GIT_BRANCH = src.ref or "";

      PACKAGE_ROOT = "gitlab.com/lightmeter/controlcenter";
      PACKAGE_VERSION = "${PACKAGE_ROOT}/version";
      APP_VERSION = "`cat VERSION.txt`";
    in [
      # Broken, staticdata.HttpAssets doesn't generate
      # "-tags='release'" # release build includes the website
      "-ldflags=-X main.Commit=${GIT_COMMIT} -X main.TagOrBranch=${GIT_BRANCH} -X main.Version=${APP_VERSION}"
    ];

  vendorSha256 = "0lkg20lxrklpn8h2vi8p4zy78fwp1qmiwmqwqpwvpajyrxqmfr7i";

  postInstall = ''
    ln -s $out/bin/controlcenter $out/bin/lightmeter
  '';
}
