{ config, lib, ... }:
let
  cfg = config.agentplot;
  hasUser = cfg.user != null;
  hasModules = cfg.hmModules != { };
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

    _contributedCliTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      internal = true;
      description = "CLI tool names contributed by agentplot services. Populated by mkClientTooling.";
    };

    serialization = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      description = ''
        JSON-serializable snapshot of evaluated agentplot capabilities for this machine/user.
        Null when agentplot.user is unset. Used by mkCapabilitiesDashboard to build
        cross-machine capability views.

        Requires claude-code and agent-deck HM modules to be present when hmModules
        is non-empty (i.e., when services are configured).
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (hasUser && hasModules) {
      home-manager.users.${cfg.user} = {
        imports = cfg.hmBaseModules ++ lib.attrValues cfg.hmModules;
      };
    })

    (lib.mkIf hasUser {
      agentplot.serialization =
        if !hasModules then
          {
            machine = config.networking.hostName;
            user = cfg.user;
            mcpServers = { };
            skills = [ ];
            cliTools = [ ];
            agentDeckMcps = { };
            profiles = { };
          }
        else
          let
            hmCfg = config.home-manager.users.${cfg.user};
            ccCfg = hmCfg.programs.claude-code;

            # Strip Nix store path context from serialized values so that
            # builtins.toJSON doesn't create cross-platform build dependencies.
            # MCP command fields like "${pkgs.foo}/bin/foo" become plain strings.
            stripContext = v:
              if builtins.isString v then builtins.unsafeDiscardStringContext v
              else if builtins.isAttrs v then lib.mapAttrs (_: stripContext) v
              else if builtins.isList v then map stripContext v
              else v;

            serializeProfile = _name: prof: {
              mcpServers = builtins.attrNames prof.mcpServers;
            };
          in
          {
            machine = config.networking.hostName;
            user = cfg.user;
            mcpServers = stripContext ccCfg.mcpServers;
            skills = builtins.attrNames hmCfg.programs.agent-skills.sources;
            cliTools = cfg._contributedCliTools;
            agentDeckMcps = stripContext hmCfg.programs.agent-deck.mcps;
            profiles = lib.mapAttrs serializeProfile ccCfg.profiles;
          };
    })
  ];
}
