# Smoke test: verify OpenClaw skill delegation from linkding client role.
# Run: nix-instantiate --eval tests/openclaw-skill-delegation.nix
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # ── Stub: programs.openclaw option definition ─────────────────────────────
  openclawOptions = { lib, ... }: {
    options.programs.openclaw = {
      skills = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = "Stub: OpenClaw skill entries";
      };
    };
  };

  # ── Mock HM modules (simulating what linkding client role generates) ──────

  # Client 1: linkding (openclaw enabled)
  linkdingPersonalHM = { ... }: {
    programs.openclaw.skills = [
      {
        name = "linkding";
        mode = "symlink";
        content = builtins.replaceStrings
          [ "name: linkding" "linkding-cli" ]
          [ "name: linkding" "linkding" ]
          (builtins.readFile ../services/linkding/skills/SKILL.md);
      }
    ];
  };

  # Client 2: linkding-biz (openclaw enabled)
  linkdingBizHM = { ... }: {
    programs.openclaw.skills = [
      {
        name = "linkding-biz";
        mode = "symlink";
        content = builtins.replaceStrings
          [ "name: linkding" "linkding-cli" ]
          [ "name: linkding-biz" "linkding-biz" ]
          (builtins.readFile ../services/linkding/skills/SKILL.md);
      }
    ];
  };

  # Client 3: disabled (no openclaw module contribution)
  linkdingDisabledHM = { ... }: { };

  # ── Test 1: Single client ─────────────────────────────────────────────────
  singleEval = lib.evalModules {
    modules = [
      openclawOptions
      linkdingPersonalHM
    ];
  };

  singleSkills = singleEval.config.programs.openclaw.skills;

  # ── Test 2: Multi-client composition ──────────────────────────────────────
  multiEval = lib.evalModules {
    modules = [
      openclawOptions
      linkdingPersonalHM
      linkdingBizHM
    ];
  };

  multiSkills = multiEval.config.programs.openclaw.skills;

  # ── Test 3: Mixed enabled/disabled ────────────────────────────────────────
  mixedEval = lib.evalModules {
    modules = [
      openclawOptions
      linkdingPersonalHM
      linkdingDisabledHM
    ];
  };

  mixedSkills = mixedEval.config.programs.openclaw.skills;

  # ── Helper: find skill by name in list ────────────────────────────────────
  findSkill = name: skills:
    let matches = builtins.filter (s: s.name == name) skills;
    in builtins.head matches;

in

# ── Single-client assertions ──────────────────────────────────────────────
assert builtins.length singleSkills == 1;
assert (builtins.head singleSkills).name == "linkding";
assert (builtins.head singleSkills).mode == "symlink";
assert builtins.isString (builtins.head singleSkills).content;
assert builtins.stringLength (builtins.head singleSkills).content > 0;

# ── Multi-client assertions ──────────────────────────────────────────────
assert builtins.length multiSkills == 2;
assert (findSkill "linkding" multiSkills).mode == "symlink";
assert (findSkill "linkding-biz" multiSkills).mode == "symlink";

# ── Content substitution assertions ──────────────────────────────────────
# linkding-biz skill content should reference "linkding-biz", not "linkding-cli"
assert lib.hasInfix "linkding-biz" (findSkill "linkding-biz" multiSkills).content;
assert !(lib.hasInfix "linkding-cli" (findSkill "linkding-biz" multiSkills).content);

# ── Mixed enabled/disabled assertions ────────────────────────────────────
assert builtins.length mixedSkills == 1;
assert (builtins.head mixedSkills).name == "linkding";

"PASS: openclaw-skill-delegation — single-client, multi-client, content substitution, mixed enabled/disabled"
