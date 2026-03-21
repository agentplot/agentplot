# Smoke test: verify clanServices compose via agentplot.hmModules and skill delegation merges correctly.
# Run: nix-instantiate --eval tests/hmModules-composition.nix
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # ── Stub: programs.claude-code option definition ──────────────────────────
  claudeCodeOptions = { lib, ... }: {
    options.programs.claude-code = {
      skills = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
        default = { };
        description = "Stub: skill contents by name";
      };
    };
  };

  # ── Mock HM modules (simulating what mkClientTooling generates) ──────────

  # Client 1: linkding (skill enabled)
  linkdingPersonalHM = { ... }: {
    programs.git.enable = true;
    programs.claude-code.skills.linkding = "mock linkding skill content";
  };

  # Client 2: linkding-biz (skill enabled)
  linkdingBizHM = { ... }: {
    programs.claude-code.skills.linkding-biz = "mock linkding-biz skill content";
  };

  # Client 3: from a different clanService (ogham-mcp)
  oghamHM = { ... }: {
    programs.bash.enable = true;
    programs.claude-code.skills.ogham-mcp = "mock ogham skill content";
  };

  # ── Part 1: Adapter-level accumulation test ────────────────────────────────
  adapterEval = lib.evalModules {
    modules = [
      ../modules/agentplot.nix
      {
        config.agentplot.hmModules.linkding-personal = linkdingPersonalHM;
        config.agentplot.hmModules.linkding-biz = linkdingBizHM;
        config.agentplot.hmModules.ogham-mcp-default = oghamHM;
        config.agentplot.user = "testuser";
      }
      # Stub home-manager.users to avoid needing actual HM
      {
        options.home-manager.users = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options.imports = lib.mkOption {
              type = lib.types.listOf lib.types.deferredModule;
              default = [ ];
            };
          });
          default = { };
        };
      }
    ];
  };

  adapterCfg = adapterEval.config;

  # ── Part 2: HM-level composition test (evaluate merged modules) ────────────
  hmEval = lib.evalModules {
    modules = [
      claudeCodeOptions
      linkdingPersonalHM
      linkdingBizHM
      oghamHM
      # Stub options consumed by mock modules
      {
        options.programs.git.enable = lib.mkOption { type = lib.types.bool; default = false; };
        options.programs.bash.enable = lib.mkOption { type = lib.types.bool; default = false; };
      }
    ];
  };

  ccSkills = hmEval.config.programs.claude-code.skills;

in

# ── Adapter assertions ──────────────────────────────────────────────────────
assert adapterCfg.agentplot.user == "testuser";
assert builtins.length (builtins.attrNames adapterCfg.agentplot.hmModules) == 3;
assert builtins.hasAttr "linkding-personal" adapterCfg.agentplot.hmModules;
assert builtins.hasAttr "linkding-biz" adapterCfg.agentplot.hmModules;
assert builtins.hasAttr "ogham-mcp-default" adapterCfg.agentplot.hmModules;
assert builtins.hasAttr "testuser" adapterCfg.home-manager.users;

# ── Single-client skill ──────────────────────────────────────────────────────
assert ccSkills.linkding == "mock linkding skill content";

# ── Multi-client merge (two linkding clients) ────────────────────────────────
assert ccSkills.linkding-biz == "mock linkding-biz skill content";

# ── Cross-service merge (linkding + ogham-mcp) ──────────────────────────────
assert ccSkills.ogham-mcp == "mock ogham skill content";
assert builtins.length (builtins.attrNames ccSkills) == 3;

"PASS: hmModules composition + claude-code skill delegation — single-client, multi-client, cross-service merge"
