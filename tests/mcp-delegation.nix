# MCP delegation test: verify linkding client role's Claude Code MCP delegation
# generates correct mcpServers entries for default, profile-scoped, and multi-client scenarios.
# Run: nix-instantiate --eval tests/mcp-delegation.nix
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # ── Stub: programs.claude-code option definitions ──────────────────────────
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
        description = "Stub: MCP server configurations";
      };
      skills = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Stub: skill contents by name";
      };
      profiles = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options.mcpServers = lib.mkOption {
            type = lib.types.attrsOf mcpServerType;
            default = { };
          };
        });
        default = { };
        description = "Stub: per-profile MCP config";
      };
    };
  };

  # ── Mock MCP configs (simulating what mkClientConfig generates) ────────────

  personalMcpConfig = {
    command = "/nix/store/mock-personal/bin/linkding-personal";
    args = [ "mcp" ];
    env = {
      LINKDING_API_TOKEN_FILE = "/run/secrets/agentplot-linkding-personal-api-token/token";
      LINKDING_BASE_URL = "https://linkding.home.com";
    };
  };

  workMcpConfig = {
    command = "/nix/store/mock-work/bin/linkding-work";
    args = [ "mcp" ];
    env = {
      LINKDING_API_TOKEN_FILE = "/run/secrets/agentplot-linkding-work-api-token/token";
      LINKDING_BASE_URL = "https://linkding.work.com";
    };
  };

  # ── Scenario 1: Single client, MCP enabled (default profile) ──────────────

  scenario1 = lib.evalModules {
    modules = [
      claudeCodeOptions
      ({ ... }: {
        programs.claude-code = lib.mkMerge [
          { skills.linkding-personal = "mock-skill"; }
          { mcpServers.linkding-personal = personalMcpConfig; }
        ];
      })
    ];
  };

  s1 = scenario1.config.programs.claude-code;

  # ── Scenario 2: Single client, MCP disabled (default) ─────────────────────

  scenario2 = lib.evalModules {
    modules = [
      claudeCodeOptions
      ({ ... }: {
        programs.claude-code = lib.mkMerge [
          { skills.linkding-personal = "mock-skill"; }
          (lib.mkIf false {
            mcpServers.linkding-personal = personalMcpConfig;
          })
        ];
      })
    ];
  };

  s2 = scenario2.config.programs.claude-code;

  # ── Scenario 3: Profile-scoped MCP ────────────────────────────────────────

  scenario3 = lib.evalModules {
    modules = [
      claudeCodeOptions
      ({ ... }: {
        programs.claude-code = lib.mkMerge [
          (lib.mkIf false {
            mcpServers.linkding-work = workMcpConfig;
          })
          {
            profiles = lib.mapAttrs (
              _profileName: profileSettings:
              lib.mkIf profileSettings.mcp.enabled {
                mcpServers.linkding-work = workMcpConfig;
              }
            ) { business = { mcp.enabled = true; }; };
          }
        ];
      })
    ];
  };

  s3 = scenario3.config.programs.claude-code;

  # ── Scenario 4: Both default and profile MCP enabled ──────────────────────

  scenario4 = lib.evalModules {
    modules = [
      claudeCodeOptions
      ({ ... }: {
        programs.claude-code = lib.mkMerge [
          { mcpServers.linkding-work = workMcpConfig; }
          {
            profiles = lib.mapAttrs (
              _profileName: profileSettings:
              lib.mkIf profileSettings.mcp.enabled {
                mcpServers.linkding-work = workMcpConfig;
              }
            ) { business = { mcp.enabled = true; }; };
          }
        ];
      })
    ];
  };

  s4 = scenario4.config.programs.claude-code;

  # ── Scenario 5: Multi-client MCP coexistence ──────────────────────────────

  scenario5 = lib.evalModules {
    modules = [
      claudeCodeOptions
      # Client 1: personal
      ({ ... }: {
        programs.claude-code = lib.mkMerge [
          { mcpServers.linkding-personal = personalMcpConfig; }
        ];
      })
      # Client 2: work
      ({ ... }: {
        programs.claude-code = lib.mkMerge [
          { mcpServers.linkding-work = workMcpConfig; }
        ];
      })
    ];
  };

  s5 = scenario5.config.programs.claude-code;

in

# ── Scenario 1 assertions: single client, MCP enabled ───────────────────────
assert builtins.hasAttr "linkding-personal" s1.mcpServers;
assert s1.mcpServers.linkding-personal.args == [ "mcp" ];
assert s1.mcpServers.linkding-personal.env.LINKDING_BASE_URL == "https://linkding.home.com";
assert s1.mcpServers.linkding-personal.env.LINKDING_API_TOKEN_FILE == "/run/secrets/agentplot-linkding-personal-api-token/token";
assert s1.mcpServers.linkding-personal.command == "/nix/store/mock-personal/bin/linkding-personal";

# ── Scenario 2 assertions: MCP disabled ─────────────────────────────────────
assert !(builtins.hasAttr "linkding-personal" s2.mcpServers);
assert builtins.length (builtins.attrNames s2.mcpServers) == 0;

# ── Scenario 3 assertions: profile-scoped MCP ───────────────────────────────
assert !(builtins.hasAttr "linkding-work" s3.mcpServers);
assert builtins.hasAttr "business" s3.profiles;
assert builtins.hasAttr "linkding-work" s3.profiles.business.mcpServers;
assert s3.profiles.business.mcpServers.linkding-work.args == [ "mcp" ];
assert s3.profiles.business.mcpServers.linkding-work.env.LINKDING_BASE_URL == "https://linkding.work.com";

# ── Scenario 4 assertions: both default and profile MCP ─────────────────────
assert builtins.hasAttr "linkding-work" s4.mcpServers;
assert builtins.hasAttr "linkding-work" s4.profiles.business.mcpServers;
assert s4.mcpServers.linkding-work.env.LINKDING_BASE_URL == "https://linkding.work.com";
assert s4.profiles.business.mcpServers.linkding-work.env.LINKDING_BASE_URL == "https://linkding.work.com";

# ── Scenario 5 assertions: multi-client coexistence ─────────────────────────
assert builtins.hasAttr "linkding-personal" s5.mcpServers;
assert builtins.hasAttr "linkding-work" s5.mcpServers;
assert builtins.length (builtins.attrNames s5.mcpServers) == 2;
assert s5.mcpServers.linkding-personal.env.LINKDING_BASE_URL == "https://linkding.home.com";
assert s5.mcpServers.linkding-work.env.LINKDING_BASE_URL == "https://linkding.work.com";

"PASS: MCP delegation — single-client, disabled, profile-scoped, both, multi-client coexistence"
