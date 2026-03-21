# Smoke test: verify linkding client role's agent-deck MCP delegation generates correct entries.
# Run: nix-instantiate --eval tests/agent-deck-mcp-delegation.nix
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # ── Stub: programs.agent-deck.mcps option definition ───────────────────────
  # Mirrors nix-agent-deck's freeform type: attrsOf (attrsOf anything)
  agentDeckOptions = { lib, ... }: {
    options.programs.agent-deck = {
      mcps = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = { };
        description = "Stub: MCP server definitions (mirrors nix-agent-deck)";
      };
    };
  };

  # ── Mock HM modules (simulating linkding client role delegation output) ────

  # Client "personal": agent-deck MCP enabled
  linkdingPersonalHM = { ... }: {
    programs.agent-deck.mcps.linkding = {
      command = "/nix/store/fake-linkding/bin/linkding";
      args = [ "mcp" ];
      env = {
        LINKDING_API_TOKEN_FILE = "/run/secrets/agentplot-linkding-personal-api-token/token";
        LINKDING_BASE_URL = "https://links.example.com";
      };
    };
  };

  # Client "biz": agent-deck MCP enabled, distinct URL
  linkdingBizHM = { ... }: {
    programs.agent-deck.mcps.linkding-biz = {
      command = "/nix/store/fake-linkding-biz/bin/linkding-biz";
      args = [ "mcp" ];
      env = {
        LINKDING_API_TOKEN_FILE = "/run/secrets/agentplot-linkding-biz-api-token/token";
        LINKDING_BASE_URL = "https://links-biz.example.com";
      };
    };
  };

  # Client "disabled": agent-deck MCP not enabled (no delegation output)
  # This client produces no programs.agent-deck entries — simulates enabled = false

  # ── Test 1: Single-client evaluation ───────────────────────────────────────
  singleEval = lib.evalModules {
    modules = [
      agentDeckOptions
      linkdingPersonalHM
    ];
  };

  singleMcps = singleEval.config.programs.agent-deck.mcps;

  # ── Test 2: Multi-client evaluation (both enabled) ────────────────────────
  multiEval = lib.evalModules {
    modules = [
      agentDeckOptions
      linkdingPersonalHM
      linkdingBizHM
    ];
  };

  multiMcps = multiEval.config.programs.agent-deck.mcps;

  # ── Test 3: Mixed enablement (only personal enabled) ──────────────────────
  mixedEval = lib.evalModules {
    modules = [
      agentDeckOptions
      linkdingPersonalHM
      # linkdingBizHM omitted — simulates agent-deck.mcp.enabled = false
    ];
  };

  mixedMcps = mixedEval.config.programs.agent-deck.mcps;

in

# ── Single-client assertions ───────────────────────────────────────────────
assert builtins.hasAttr "linkding" singleMcps;
assert builtins.length (builtins.attrNames singleMcps) == 1;

# Structure: command, args, env keys present
assert builtins.hasAttr "command" singleMcps.linkding;
assert builtins.hasAttr "args" singleMcps.linkding;
assert builtins.hasAttr "env" singleMcps.linkding;

# command is a string containing /bin/
assert builtins.isString singleMcps.linkding.command;
assert lib.hasInfix "/bin/" singleMcps.linkding.command;

# args is a list
assert builtins.isList singleMcps.linkding.args;
assert singleMcps.linkding.args == [ "mcp" ];

# env is an attrset with correct keys and values
assert builtins.isAttrs singleMcps.linkding.env;
assert singleMcps.linkding.env.LINKDING_BASE_URL == "https://links.example.com";
assert builtins.hasAttr "LINKDING_API_TOKEN_FILE" singleMcps.linkding.env;

# ── Multi-client assertions ────────────────────────────────────────────────
assert builtins.hasAttr "linkding" multiMcps;
assert builtins.hasAttr "linkding-biz" multiMcps;
assert builtins.length (builtins.attrNames multiMcps) == 2;

# Each entry has distinct base URLs
assert multiMcps.linkding.env.LINKDING_BASE_URL == "https://links.example.com";
assert multiMcps.linkding-biz.env.LINKDING_BASE_URL == "https://links-biz.example.com";

# Each entry has distinct commands
assert multiMcps.linkding.command != multiMcps.linkding-biz.command;

# ── Mixed enablement assertions ────────────────────────────────────────────
assert builtins.hasAttr "linkding" mixedMcps;
assert !(builtins.hasAttr "linkding-biz" mixedMcps);
assert builtins.length (builtins.attrNames mixedMcps) == 1;

"PASS: agent-deck MCP delegation — single-client, multi-client, mixed enablement, config structure"
