{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.lightmeter;

  flags = concatStringsSep " " (mapAttrsToList
    (flag: v: "-${flag}${optionalString (v != null) " ${toString v}"}")
    cfg.flags);
in
{
  options.services.lightmeter = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the Lightmeter monitoring service
      '';
    };

    port = mkOption {
      type = types.int;
      default = 8080;
      description = ''
        Port for Lightmeter to listen on
      '';
    };

    flags = mkOption {
      type = with types; attrsOf (nullOr (oneOf [ bool int float str path ]));
      default = {};
      description = ''
        Command line options to pass to lightmeter
      '';
    };
  };

  config = mkIf cfg.enable {
    services.lightmeter.flags = mapAttrs (_: mkDefault)
      {
        listen = ":${toString cfg.port}";
        workspace = "/var/lib/lightmeter";
      };

    systemd.services.lightmeter = {
      wantedBy = [ "multi-user.target" ];

      description = "Lightmeter Monitoring Service";

      serviceConfig = {
        User = "lightmeter";
        Group = "lightmeter";

        StateDirectory = "lightmeter";
        StateDirectoryMode = "0750";
        WorkingDirectory = pkgs.lightmeter.src;

        ExecStart = "${pkgs.lightmeter}/bin/lightmeter ${flags}";
      };
    };

    users = {
      users.lightmeter = {
        group = "lightmeter";
        description = "Lightmeter user";
      };

      groups.lightmeter = { };
    };
  };
}
