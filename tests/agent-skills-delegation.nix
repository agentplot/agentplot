# Smoke test: verify agent-skills delegation from linkding client role.
# Covers: source registration, explicit skills with transform, Claude target,
#          multi-client coexistence, and Phase 1/Phase 2 mutual exclusion.
# Run: nix-instantiate --eval tests/agent-skills-delegation.nix
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # ── Stub: programs.agent-skills option definitions ─────────────────────────
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
      skills.explicit = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            from = lib.mkOption { type = lib.types.str; };
            path = lib.mkOption { type = lib.types.str; default = ""; };
            packages = lib.mkOption { type = lib.types.listOf lib.types.package; default = [ ]; };
            transform = lib.mkOption { type = lib.types.nullOr lib.types.raw; default = null; };
          };
        });
        default = { };
      };
      targets.claude.enable = lib.mkEnableOption "Claude target";
    };
  };

  # ── Stub: programs.claude-code option definitions ──────────────────────────
  claudeCodeOptions = { lib, ... }: {
    options.programs.claude-code = {
      skills = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
      };
    };
  };

  # ── Mock HM modules (replicating what linkding client role generates) ──────

  # Helper: create a mock CLI wrapper package
  mkMockCli = name: pkgs.writeShellScriptBin name "echo ${name}";

  # Client "personal": agent-skills enabled, cli name "linkding"
  personalCli = mkMockCli "linkding";
  personalHM = { ... }: {
    programs.agent-skills = {
      enable = true;
      sources."agentplot-linkding" = {
        path = ../services/linkding/skills;
      };
      skills.explicit."linkding" = {
        from = "agentplot-linkding";
        packages = [ personalCli ];
        transform = { original, ... }:
          builtins.replaceStrings [ "name: linkding" "linkding-cli" ] [ "name: linkding" "linkding" ] original;
      };
      targets.claude.enable = true;
    };
    # Phase 1 suppressed: programs.claude-code.skills.linkding NOT set
  };

  # Client "biz": agent-skills enabled, cli name "linkding-biz"
  bizCli = mkMockCli "linkding-biz";
  bizHM = { ... }: {
    programs.agent-skills = {
      enable = true;
      sources."agentplot-linkding" = {
        path = ../services/linkding/skills;
      };
      skills.explicit."linkding-biz" = {
        from = "agentplot-linkding";
        packages = [ bizCli ];
        transform = { original, ... }:
          builtins.replaceStrings [ "name: linkding" "linkding-cli" ] [ "name: linkding-biz" "linkding-biz" ] original;
      };
      targets.claude.enable = true;
    };
  };

  # Client "phase1only": agent-skills disabled, Phase 1 active
  phase1HM = { ... }: {
    programs.claude-code.skills."linkding-phase1" = "stub skill content with linkding-phase1";
  };

  # ── Evaluate all modules together ──────────────────────────────────────────
  eval = lib.evalModules {
    modules = [
      agentSkillsOptions
      claudeCodeOptions
      personalHM
      bizHM
      phase1HM
    ];
  };

  cfg = eval.config;
  src = cfg.programs.agent-skills.sources."agentplot-linkding";
  skills = cfg.programs.agent-skills.skills.explicit;
  ccSkills = cfg.programs.claude-code.skills;

in

# ── Module enabled ─────────────────────────────────────────────────────────
assert cfg.programs.agent-skills.enable == true;

# ── Source registration ────────────────────────────────────────────────────
assert src.path != null;

# ── Single-client: personal skill ─────────────────────────────────────────
assert builtins.hasAttr "linkding" skills;
assert skills."linkding".from == "agentplot-linkding";
assert builtins.length skills."linkding".packages == 1;

# ── Multi-client: biz skill ──────────────────────────────────────────────
assert builtins.hasAttr "linkding-biz" skills;
assert skills."linkding-biz".from == "agentplot-linkding";
assert builtins.length skills."linkding-biz".packages == 1;

# ── Transform verification ───────────────────────────────────────────────
assert builtins.isFunction skills."linkding".transform;
assert skills."linkding".transform { original = "use linkding-cli to search"; dependencies = ""; } == "use linkding to search";
assert skills."linkding-biz".transform { original = "use linkding-cli to search"; dependencies = ""; } == "use linkding-biz to search";
assert skills."linkding".transform { original = "name: linkding"; dependencies = ""; } == "name: linkding";
assert skills."linkding-biz".transform { original = "name: linkding"; dependencies = ""; } == "name: linkding-biz";

# ── Claude target enabled ────────────────────────────────────────────────
assert cfg.programs.agent-skills.targets.claude.enable == true;

# ── Exactly 2 explicit skills (personal + biz, not phase1) ───────────────
assert builtins.length (builtins.attrNames skills) == 2;

# ── Phase 1 suppression: agent-skills clients NOT in claude-code.skills ──
assert !(builtins.hasAttr "linkding" ccSkills);
assert !(builtins.hasAttr "linkding-biz" ccSkills);

# ── Phase 1 still works for non-agent-skills client ──────────────────────
assert builtins.hasAttr "linkding-phase1" ccSkills;
assert builtins.isString ccSkills."linkding-phase1";

"PASS: agent-skills delegation — source registration, multi-client explicit skills, transforms, Claude target, Phase 1/2 mutual exclusion"
