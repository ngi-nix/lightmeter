{ buildGoModule, buildGoPackage }:
{ src, version }:

buildGoModule {
  pname = "lightmeter";
  inherit version src;

  # require the inconsistent vendors in go.mod
  # buildGoPackage errors out with missing dependency
  patches = [ ./consistent-vendoring.patch ];
  vendorSha256 = "1maqpk8h4qini8lv6csrynnnfv9655z879r1fr56f3q8g5mbkq2a";

  buildFlagsArray =
    let
      GIT_COMMIT = src.rev or "";
      GIT_BRANCH = src.ref or "";

      PACKAGE_ROOT = "gitlab.com/lightmeter/controlcenter";
      PACKAGE_VERSION = "${PACKAGE_ROOT}/version";
      APP_VERSION = "`cat VERSION.txt`";
    in [
      "-tags='release'" # release build includes the website
      ''-ldflags="-X main.Commit=${GIT_COMMIT} -X main.TagOrBranch=${GIT_BRANCH} -X main.Version=${APP_VERSION}"''
    ];

  # Manually generate the static website file, makes release build work
  preBuild = ''
    make static_www
  '';

  postInstall = ''
    ln -s $out/bin/controlcenter $out/bin/lightmeter
  '';
}
