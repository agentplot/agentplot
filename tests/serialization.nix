# Smoke test: verify agentplot.serialization extracts evaluated HM config into a
# JSON-serializable attrset with the correct shape.
# Run: nix-instantiate --eval tests/serialization.nix
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # ── Stub option definitions (mirroring real HM modules) ────────────────────

  mcpServerType = lib.types.submodule {
    options = {
      command = lib.mkOption { type = lib.types.str; };
      args = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
      env = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
    };
  };

  claudeCodeOptions = { lib, ... }: {
    options.programs.claude-code = {
      mcpServers = lib.mkOption {
        type = lib.types.attrsOf mcpServerType;
        default = { };
      };
      skills = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
      };
      profiles = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options.mcpServers = lib.mkOption {
            type = lib.types.attrsOf mcpServerType;
            default = { };
          };
        });
        default = { };
      };
    };
  };

  agentSkillsOptions = { lib, ... }: {
    options.programs.agent-skills = {
      enable = lib.mkEnableOption "agent-skills";
      sources = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            path = lib.mkOption { type = lib.types.nullOr lib.types.path; default = null; };
            input = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
            subdir = lib.mkOption { type = lib.types.str; default = "."; };
          };
        });
        default = { };
      };
    };
  };

  agentDeckOptions = { lib, ... }: {
    options.programs.agent-deck = {
      mcps = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = { };
      };
    };
  };

  # Stubs for NixOS-level options the module reads
  nixosStubs = { lib, ... }: {
    options.networking.hostName = lib.mkOption {
      type = lib.types.str;
      default = "unnamed";
    };
    options.home-manager.users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submoduleWith {
        modules = [ claudeCodeOptions agentSkillsOptions agentDeckOptions ];
      });
      default = { };
    };
  };

  # ── Test 1: Smoke test — full config with services ─────────────────────────

  fullEval = lib.evalModules {
    modules = [
      ../modules/agentplot.nix
      nixosStubs
      {
        config.networking.hostName = "mac-studio";
        config.agentplot.user = "chuck";
        config.agentplot._contributedCliTools = [ "linkding-biz" "subcog-personal" ];
        config.agentplot.hmModules.linkding-biz = { ... }: {
          programs.claude-code.mcpServers.linkding-biz = {
            command = "/nix/store/mock/bin/linkding-biz";
            args = [ "mcp" ];
            env = {
              LINKDING_BASE_URL = "https://links.biz.example.com";
              LINKDING_API_TOKEN_FILE = "/run/secrets/token";
            };
          };
          programs.agent-skills.sources."agentplot-linkding" = {
            path = ../services/linkding/skills;
          };
          programs.agent-deck.mcps.linkding-biz = {
            command = "/nix/store/mock/bin/linkding-biz";
            args = [ "mcp" ];
            env.LINKDING_BASE_URL = "https://links.biz.example.com";
          };
        };
        config.agentplot.hmModules.subcog-personal = { ... }: {
          programs.claude-code.mcpServers.subcog-personal = {
            command = "/nix/store/mock/bin/subcog";
            args = [ "mcp" ];
            env.SUBCOG_BASE_URL = "https://subcog.example.com";
          };
          programs.claude-code.profiles.business.mcpServers.linkding-biz = {
            command = "/nix/store/mock/bin/linkding-biz";
            args = [ "mcp" ];
          };
          programs.claude-code.profiles.personal.mcpServers.subcog-personal = {
            command = "/nix/store/mock/bin/subcog";
            args = [ "mcp" ];
          };
          programs.agent-skills.sources."agentplot-subcog" = {
            path = ./.;
          };
        };
      }
    ];
  };

  s = fullEval.config.agentplot.serialization;

  # ── Test 2: Null user — serialization is null ──────────────────────────────

  nullUserEval = lib.evalModules {
    modules = [
      ../modules/agentplot.nix
      nixosStubs
      { config.networking.hostName = "test-machine"; }
    ];
  };

  # ── Test 3: User set, no modules — empty collections ──────────────────────

  emptyModulesEval = lib.evalModules {
    modules = [
      ../modules/agentplot.nix
      nixosStubs
      {
        config.networking.hostName = "empty-machine";
        config.agentplot.user = "nobody";
      }
    ];
  };

  emptyS = emptyModulesEval.config.agentplot.serialization;

in

# ── Test 1: Smoke test assertions ──────────────────────────────────────────

# Shape: all expected keys present
assert s != null;
assert builtins.hasAttr "machine" s;
assert builtins.hasAttr "user" s;
assert builtins.hasAttr "mcpServers" s;
assert builtins.hasAttr "skills" s;
assert builtins.hasAttr "cliTools" s;
assert builtins.hasAttr "agentDeckMcps" s;
assert builtins.hasAttr "profiles" s;

# Identification fields
assert s.machine == "mac-studio";
assert s.user == "chuck";

# MCP servers: two entries with correct structure
assert builtins.length (builtins.attrNames s.mcpServers) == 2;
assert builtins.hasAttr "linkding-biz" s.mcpServers;
assert builtins.hasAttr "subcog-personal" s.mcpServers;
assert s.mcpServers.linkding-biz.command == "/nix/store/mock/bin/linkding-biz";
assert s.mcpServers.linkding-biz.args == [ "mcp" ];
assert s.mcpServers.linkding-biz.env.LINKDING_BASE_URL == "https://links.biz.example.com";

# Skills: source names extracted
assert builtins.isList s.skills;
assert builtins.elem "agentplot-linkding" s.skills;
assert builtins.elem "agentplot-subcog" s.skills;
assert builtins.length s.skills == 2;

# CLI tools: from internal tracking option
assert builtins.isList s.cliTools;
assert builtins.elem "linkding-biz" s.cliTools;
assert builtins.elem "subcog-personal" s.cliTools;

# Agent-deck MCPs
assert builtins.hasAttr "linkding-biz" s.agentDeckMcps;
assert s.agentDeckMcps.linkding-biz.env.LINKDING_BASE_URL == "https://links.biz.example.com";

# Profiles: MCP server names as lists
assert builtins.hasAttr "business" s.profiles;
assert builtins.hasAttr "personal" s.profiles;
assert builtins.elem "linkding-biz" s.profiles.business.mcpServers;
assert builtins.elem "subcog-personal" s.profiles.personal.mcpServers;

# ── Test 2: Null user ─────────────────────────────────────────────────────
assert nullUserEval.config.agentplot.serialization == null;

# ── Test 3: Empty modules ─────────────────────────────────────────────────
assert emptyS != null;
assert emptyS.machine == "empty-machine";
assert emptyS.user == "nobody";
assert emptyS.mcpServers == { };
assert emptyS.skills == [ ];
assert emptyS.cliTools == [ ];
assert emptyS.agentDeckMcps == { };
assert emptyS.profiles == { };

# ── Test 4: JSON roundtrip — builtins.toJSON succeeds ─────────────────────
assert builtins.isString (builtins.toJSON s);
assert builtins.isString (builtins.toJSON emptyS);

"PASS: serialization — smoke test, null-user, empty-modules, JSON roundtrip"
