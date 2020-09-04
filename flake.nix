{
  description = "Lightmeter mail delivery monitoring";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; ref = "nixos-20.03"; };

  # Upstream source tree(s).
  inputs.lightmeter-src = { type = "gitlab"; owner = "lightmeter"; repo = "controlcenter"; flake = false; };
  inputs.nixos-mailserver-src = { type = "gitlab"; owner = "simple-nixos-mailserver"; repo = "nixos-mailserver"; ref = "nixos-20.03"; flake = false; };
  inputs.nixcloud-webservices-src = { type = "github"; owner = "nixcloud"; repo = "nixcloud-webservices"; flake = false; };

  outputs = { self, nixpkgs, ... }@inputs:
    let

      # Generate a user-friendly version numer.
      versions =
        let
          generateVersion = builtins.substring 0 8;
        in
        nixpkgs.lib.genAttrs
          [ "lightmeter" ]
          (n: generateVersion inputs."${n}-src".lastModifiedDate);

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev:
        with final;
        {

          lightmeter = callPackage ./pkgs/lightmeter {} {
            src = inputs.lightmeter-src;
            version = versions.lightmeter;
          };

        };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system})
            lightmeter;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.lightmeter);

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      nixosModules.lightmeter = import ./modules/lightmeter.nix;

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems (system: {
        inherit (self.packages.${system}) hello;

        # Additional tests, if applicable.
        test =
          with nixpkgsFor.${system};
          stdenv.mkDerivation {
            name = "hello-test-${version}";

            buildInputs = [ hello ];

            unpackPhase = "true";

            buildPhase = ''
              echo 'running some integration tests'
              [[ $(hello) = 'Hello, world!' ]]
            '';

            installPhase = "mkdir -p $out";
          };

        # A VM test of the NixOS module.
        vmTest =
          with import (nixpkgs + "/nixos/lib/testing-python.nix") {
            inherit system;
          };

          makeTest {
            nodes = {
              client = { ... }: {
                imports = [ self.nixosModules.hello ];
              };
            };

            testScript =
              ''
                start_all()
                client.wait_for_unit("multi-user.target")
                client.succeed("hello")
              '';
          };
      });

    };
}
