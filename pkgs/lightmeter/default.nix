{ buildGoModule
, ragel, nodePackages }:
{ src, version }:

buildGoModule {
  pname = "lightmeter";
  inherit version src;

  nativeBuildInputs = [ ragel nodePackages.vue-cli ];

  deleteVendor = false;
  vendorSha256 = null;

  buildPhase =
    let
      GIT_COMMIT = src.rev or "";
      GIT_BRANCH = src.ref or "";
    in
    ''
      runHook preBuild

      sed -i 's@\(GIT_COMMIT = \)""@\1 "${GIT_COMMIT}"@' Makefile
      sed -i 's@\(GIT_BRANCH = \)""@\1 "${GIT_BRANCH}"@' Makefile

      make release

      runHook postBuild
    '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp lightmeter $out/bin

    runHook postBuild
  '';

  doCheck = true;
}
