{ buildGoModule, buildGoPackage }:
{ src, version }:

buildGoModule {
  pname = "lightmeter";
  inherit version src;

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
    make static_www domain_mapping_list po2go
  '';

  postInstall = ''
    ln -s $out/bin/controlcenter $out/bin/lightmeter
  '';
}
