# Smoke test: verify clanServices compose via agentplot.hmModules and claude-tools delegation merges correctly.
# Run: nix-instantiate --eval tests/hmModules-composition.nix
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # ── Stub: programs.claude-tools option definition ──────────────────────────
  claudeToolsOptions = { lib, ... }: {
    options.programs.claude-tools = {
      skills-installer.skillsByClient = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        default = { };
        description = "Stub: skills registered per target per client name";
      };
    };
  };

  # ── Mock HM modules (simulating what linkding client role generates) ───────

  # Client 1: linkding (claude-tools enabled)
  linkdingPersonalHM = { ... }: {
    programs.git.enable = true;
    programs.claude-tools.skills-installer.skillsByClient.claude-code.linkding = "symlink";
  };

  # Client 2: linkding-biz (claude-tools enabled)
  linkdingBizHM = { ... }: {
    programs.claude-tools.skills-installer.skillsByClient.claude-code.linkding-biz = "symlink";
  };

  # Client 3: from a different clanService (paperless)
  paperlessHM = { ... }: {
    programs.bash.enable = true;
    programs.claude-tools.skills-installer.skillsByClient.claude-code.paperless = "symlink";
  };

  # ── Part 1: Adapter-level accumulation test ────────────────────────────────
  adapterEval = lib.evalModules {
    modules = [
      ../modules/agentplot.nix
      {
        config.agentplot.hmModules.linkding-personal = linkdingPersonalHM;
        config.agentplot.hmModules.linkding-biz = linkdingBizHM;
        config.agentplot.hmModules.paperless-default = paperlessHM;
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
      claudeToolsOptions
      linkdingPersonalHM
      linkdingBizHM
      paperlessHM
      # Stub options consumed by mock modules
      {
        options.programs.git.enable = lib.mkOption { type = lib.types.bool; default = false; };
        options.programs.bash.enable = lib.mkOption { type = lib.types.bool; default = false; };
      }
    ];
  };

  skillsByClient = hmEval.config.programs.claude-tools.skills-installer.skillsByClient;

in

# ── Adapter assertions ──────────────────────────────────────────────────────
assert adapterCfg.agentplot.user == "testuser";
assert builtins.length (builtins.attrNames adapterCfg.agentplot.hmModules) == 3;
assert builtins.hasAttr "linkding-personal" adapterCfg.agentplot.hmModules;
assert builtins.hasAttr "linkding-biz" adapterCfg.agentplot.hmModules;
assert builtins.hasAttr "paperless-default" adapterCfg.agentplot.hmModules;
assert builtins.hasAttr "testuser" adapterCfg.home-manager.users;

# ── Single-client delegation ────────────────────────────────────────────────
assert skillsByClient.claude-code.linkding == "symlink";

# ── Multi-client merge (two linkding clients) ──────────────────────────────
assert skillsByClient.claude-code.linkding-biz == "symlink";

# ── Cross-service merge (linkding + paperless) ─────────────────────────────
assert skillsByClient.claude-code.paperless == "symlink";
assert builtins.length (builtins.attrNames skillsByClient.claude-code) == 3;

"PASS: hmModules composition + claude-tools delegation — single-client, multi-client, cross-service merge"
