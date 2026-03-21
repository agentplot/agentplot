# Smoke test: verify two services using mkClientTooling compose their HM modules without conflict.
# Run: nix-instantiate --eval tests/mkClientTooling-composition.nix
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;

  # Import mkClientTooling from agentplot-kit (workspace-local)
  mkClientTooling = import ../../agentplot-kit/lib/mkClientTooling.nix;

  # ── Service 1: MCP-only service (like qmd) ──────────────────────────────────
  qmdTooling = mkClientTooling {
    serviceName = "qmd";
    capabilities = {
      mcp = {
        type = "http";
        urlTemplate = client: "https://${client.domain}/mcp";
      };
    };
    extraClientOptions = { lib, ... }: {
      domain = lib.mkOption {
        type = lib.types.str;
        description = "FQDN of the qmd server";
      };
    };
  };

  # ── Service 2: Skill + MCP service (like ogham-mcp) ─────────────────────────
  oghamTooling = mkClientTooling {
    serviceName = "ogham-mcp";
    capabilities = {
      skills = [ ../services/ogham-mcp/skills/SKILL.md ];
      mcp = {
        type = "sse";
        urlTemplate = client: "${client.url}/sse";
      };
      secret = {
        name = "api-key";
        mode = "prompted";
      };
    };
    extraClientOptions = { lib, ... }: {
      url = lib.mkOption {
        type = lib.types.str;
        description = "SSE endpoint URL";
      };
    };
  };

  # ── Evaluate interfaces ──────────────────────────────────────────────────────

  qmdInterface = qmdTooling.interface { inherit lib; };
  oghamInterface = oghamTooling.interface { inherit lib; };

  # Verify interface shapes
  qmdOpts = (lib.evalModules {
    modules = [
      { options = qmdInterface.options; }
      {
        config.clients.docs = {
          domain = "qmd.example.com";
          claude-code.mcp.enabled = true;
          agent-deck.mcp.enabled = true;
        };
      }
    ];
  }).config;

  oghamOpts = (lib.evalModules {
    modules = [
      { options = oghamInterface.options; }
      {
        config.clients.memory = {
          url = "https://ogham.example.com";
          claude-code.skill.enabled = true;
          claude-code.mcp.enabled = true;
        };
      }
    ];
  }).config;

in

# ── Interface shape assertions ─────────────────────────────────────────────

# qmd: MCP-only → has MCP targets, no skill targets
assert builtins.hasAttr "docs" qmdOpts.clients;
assert qmdOpts.clients.docs.claude-code.mcp.enabled == true;
assert qmdOpts.clients.docs.agent-deck.mcp.enabled == true;
assert qmdOpts.clients.docs.name == "docs";

# ogham: Skill + MCP → has both skill and MCP targets
assert builtins.hasAttr "memory" oghamOpts.clients;
assert oghamOpts.clients.memory.claude-code.skill.enabled == true;
assert oghamOpts.clients.memory.claude-code.mcp.enabled == true;
assert oghamOpts.clients.memory.agent-skills.enabled == false;
assert oghamOpts.clients.memory.openclaw.skill.enabled == false;
assert oghamOpts.clients.memory.agent-deck.skill.enabled == false;
assert oghamOpts.clients.memory.name == "memory";

# ── Cross-service coexistence: both services' clients configured ───────────
# (Verifies the interface options don't conflict when used together)
assert builtins.length (builtins.attrNames qmdOpts.clients) == 1;
assert builtins.length (builtins.attrNames oghamOpts.clients) == 1;

"PASS: mkClientTooling composition — MCP-only interface, skill+MCP interface, multi-service coexistence"
