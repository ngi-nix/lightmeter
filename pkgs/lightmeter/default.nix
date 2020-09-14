{ buildGoModule, buildGoPackage }:
{ src, version }:

buildGoModule {
  pname = "lightmeter";
  inherit version src;

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
}
