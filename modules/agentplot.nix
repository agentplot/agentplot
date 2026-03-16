{ config, lib, ... }:
let
  cfg = config.agentplot;
in
{
  options.agentplot = {
    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Username to wire accumulated HM modules into via home-manager.users.<user>";
    };

    hmModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = ''
        Accumulated Home Manager modules from agentplot clanService client roles.
        Each key is a service-client identifier (e.g., "linkding-personal").
        The adapter wires all entries into home-manager.users.''${agentplot.user}.
      '';
    };
  };

  config = lib.mkIf (cfg.user != null && cfg.hmModules != { }) {
    home-manager.users.${cfg.user} = {
      imports = lib.attrValues cfg.hmModules;
    };
  };
}
