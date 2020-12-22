{
  description = "Lightmeter mail delivery monitoring";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; ref = "nixos-20.09"; };

  # Flake compatability shim
  inputs.flake-compat = { type = "github"; owner = "edolstra"; repo = "flake-compat"; flake = false; };

  # Upstream source tree(s).
  inputs.lightmeter-src = { type = "git"; url = "https://gitlab.com/lightmeter/controlcenter.git"; flake = false; };

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
        with final.pkgs;
        {

          lightmeter = callPackage ./pkgs/lightmeter { } {
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

      # NixOS system configuration, if applicable
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Hardcoded
        modules = [
          # VM-specific configuration
          ({ modulesPath, pkgs, ... }: {
            imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
            virtualisation.qemu.options = [ "-m 2G" "-vga virtio" ];
            environment.systemPackages = with pkgs; [ st unzip ripgrep chromium ];

            networking.hostName = "vm";
            networking.networkmanager.enable = true;

            services.xserver.enable = true;
            services.xserver.layout = "us";
            services.xserver.windowManager.i3.enable = true;
            services.xserver.displayManager.lightdm.enable = true;

            users.mutableUsers = false;
            users.users.user = {
              password = "user"; # yes, very secure, I know
              createHome = true;
              isNormalUser = true;
              extraGroups = [ "wheel" ];
            };
          })

          # Flake specific support
          ({ ... }: {
            imports = builtins.attrValues self.nixosModules;
            nixpkgs.overlays = [ self.overlay ];
          })

          # Lightmeter configuration
          ({ ... }: {
            environment.etc."postfix/mail.log".source = ./sample/sample.log;

            services.lightmeter.enable = true;
            # services.lightmeter.flags.watch_file = "/etc/postfix/mail.log";
            services.lightmeter.flags.watch_dir = "/etc/postfix";
          })
        ];
      };

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems (system: self.packages.${system} // {

        # Reachability test of the hosted software
        lightmeter-reachable =
          with import (nixpkgs + "/nixos/lib/testing-python.nix")
            {
              inherit system;
            };

          makeTest {
            nodes.client = { ... }: {
              imports = builtins.attrValues self.nixosModules;
              nixpkgs.overlays = [ self.overlay ];

              environment.etc."postfix/mail.log".source = ./sample/sample.log;
              services.lightmeter.enable = true;
              services.lightmeter.port = 7025; # might as well since it's an option
              # either watch_file or watch_dir needs to be specified
              services.lightmeter.flags.watch_file = "/etc/postfix/mail.log";
            };

            testScript =
              ''
                start_all()

                client.wait_for_unit("lightmeter.service")
                client.wait_for_open_port(7025)
                client.succeed("curl http://localhost:7025")

                client.shutdown()
              '';
          };
      });

    };
}
