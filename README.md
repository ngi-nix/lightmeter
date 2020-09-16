## Lightmeter [Nixified]

Funded by the European Commission under the [Next Generation Internet](https://www.ngi.eu/ngi-projects/ngi-zero/) initiative

### Objective

1. Package Lightmeter for NixOS
2. Allow usage of Lightmeter through the module system for NixOS

### Current State

As of 2020, September 16, this flake is in a working state and achieving all of its objectives.

### Usage

Instructions were last updated on 2020, September 16.

#### Building the Package (Nix)

If you are using Nix 2.x, compatibility is provided through `github:edolstra/flake-compat`, as such the package can be built with just `nix-build` in the current directory or more verbosely, `nix-build -A packages.x86_64-linux.lightmeter`. If you do not want to clone the repository, then you can add the repository into `NIX_PATH` by including `-I lightmeter=https://github.com/ngi-nix/lightmeter/tarball/master '<lightmeter>'` which can also be pinned at a certain commit, such as `a32bfe25a5c8bafa0297a75327693b13240723ea`.

If you are using Nix 3.x, cloning the repository isn't needed and one can just run `nix build github:ngi-nix/lightmeter` or more verbosely, `nix build --print-build-logs github:ngi-nix/lightmeter#packages.x86_64-linux.lightmeter`.

#### Using the Module (NixOS)

To enable the lightmeter module in NixOS, you will have to use `./modules/lightmeter.nix` and package in `./pkgs/lightmeter/default.nix`

This will only cover the flake-based approach (Nix 3.x), but can be expanded for Nix 2.x compatibility.

To include `github:ngi-nix/lightmeter` into your flake, you will first have to include it as an input like the following

```nix
{
  #...
  # Can be consistently pinned at a certain revision with `rev = ""`
  inputs.lightmeter = { type = "github"; owner = "ngi-nix"; repo = "lightmeter"; };
  #...
  # Or just `{ self, nixpkgs, lightmeter }` but that doesn't cover all cases
  outputs = { self, nixpkgs, ... }@inputs:
  #...
}
```

Before including the module and overlay into the system configuration

```nix
{
  #...
  nixosConfigurations.<name> = nixpkgs.lib.nixosSystem {
    system = "<system>";
    modules = [
      #...
      ({ ... }: {
        # Or just `imports = [ inputs.lightmeter.nixosModules.lightmeter ]`
        imports = builtins.attrValues inputs.lightmeter.nixosModules;
        nixpkgs.overlays = [ inputs.lightmeter.overlay ];
      })
      #...
    ];
  };
  #...
}
```

In which you can enable the service afterwards

```nix
{
  #...
  nixosConfigurations.<name> = nixpkgs.lib.nixosSystem {
    system = "<system>";
    modules = [
      #...
      ({ ... }: {
        services.lightmeter.enable = true;
        # Or to watch a file use the following command
        #   services.lightmeter.flags.watch_file = "/etc/postfix/mail.log";
        services.lightmeter.flags.watch_dir = "/etc/postfix";
      })
      #...
    ];
  };
  #...
}
```

#### Using the Virtual Machine Testbed

See `./REVIEW.md`
