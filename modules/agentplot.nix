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

    hmBaseModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [ ];
      description = ''
        Framework-level Home Manager modules imported alongside per-service modules.
        Used to provide option definitions (e.g., programs.agent-skills from agent-skills-nix)
        that service HM modules depend on.
      '';
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
      imports = cfg.hmBaseModules ++ lib.attrValues cfg.hmModules;
    };
  };
}
