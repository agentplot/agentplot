## Context

The fleet dashboard provides a cross-machine view of deployed services by consuming `inventorySerialization` — a single pre-assembled blob from clan-core. It works at the inventory/declaration level.

The capabilities dashboard needs to show the **evaluated result** of Home Manager module merging — what MCP servers, skills, CLI tools, and profiles each user actually gets on each machine. This data only exists after NixOS/Darwin module evaluation, not at the inventory level.

The existing `modules/agentplot.nix` is the merge point where all service HM modules accumulate into `home-manager.users.<user>`. It has access to the final evaluated config.

## Goals / Non-Goals

**Goals:**
- Provide a `config.agentplot.serialization` option that extracts the evaluated agentplot-relevant HM config into a JSON-serializable attrset
- Mirror the fleet dashboard API: `lib.mkCapabilitiesDashboard { pkgs; capabilitiesSerialization; }` produces a self-contained HTML SPA
- Support multi-machine, multi-user assembly in the consuming repo
- Show a capability matrix: machine × user, with MCP servers, skills, CLI tools, agent-deck MCPs, and Claude Code profiles

**Non-Goals:**
- Real-time or dynamic data — this is a build-time artifact like the fleet dashboard
- Modifying mkClientTooling or service definitions

## Decisions

### 1. Serialization lives in `agentplot.nix`

The serialization option goes in `modules/agentplot.nix` because it already has access to the merged HM config via `home-manager.users.${cfg.user}`. It reads the evaluated config and produces a plain attrset.

**Alternative: serialization helper function in lib.** Rejected because the consumer would need to know the exact HM option paths to extract, coupling them to internal structure. The module knows its own shape.

### 2. Per-machine serialization, consumer assembles

Each machine's `config.agentplot.serialization` produces one blob (machine name, user, capabilities). The consuming repo collects these into `capabilitiesSerialization.machines = { <name> = config.agentplot.serialization; ... }`.

This differs from the fleet dashboard where clan provides one pre-assembled blob. The reason: HM config is per-machine evaluated, there's no cross-machine primitive in NixOS. The assembly step is small — just collecting attrsets into a dict — but **must be documented clearly** since the consumer needs to:
1. Reference each machine's evaluated config (nixosConfigurations/darwinConfigurations)
2. Build the `machines` attrset manually
3. Pass it to `mkCapabilitiesDashboard`

**Alternative: auto-discovery from clan inventory.** Rejected because the capability data requires full module evaluation, which clan's inventory layer doesn't provide.

### 3. Serialization data model

```nix
agentplot.serialization = {
  machine = "<hostname>";       # from networking.hostName
  user = "<username>";          # from agentplot.user
  mcpServers = {                # from programs.claude-code.mcpServers
    linkding-biz = { type = "http"; url = "..."; };
    ogham-mcp = { type = "sse"; url = "..."; };
  };
  skills = [ "agentplot-linkding-biz" "agentplot-subcog" ... ];
  cliTools = [ "linkding-biz" "subcog-personal" ... ];
  agentDeckMcps = {             # from programs.agent-deck.mcps
    subcog-personal = { ... };
  };
  profiles = {                  # from programs.claude-code.profiles
    business = {
      mcpServers = [ "linkding-biz" "subcog-personal" ];
    };
    personal = {
      mcpServers = [ "linkding-personal" "ogham-mcp" ];
    };
  };
};
```

Skills and CLI tools are lists (names only). MCP servers and profiles retain their config structure since type/URL are useful in the dashboard.

### 4. Dashboard HTML mirrors fleet dashboard pattern

Same approach: self-contained SPA with embedded JSON, dark theme, no external dependencies. Template placeholder `__CAPABILITIES_JSON__` replaced at build time.

The primary view is a **machine card grid** (like fleet dashboard's machines view). Each card shows the user and their capabilities grouped by type. A secondary view could show a **capability matrix** (rows = capabilities, columns = machines) for cross-machine comparison.

### 5. `mkCapabilitiesInventory` for JSON-only export

Same as `mkFleetInventory` — a plain JSON file for programmatic consumption, CI checks, or diffing between builds.

### 6. First-class dashboard serving via `agentplot.dashboards` module

A new NixOS/Darwin module at `modules/dashboards.nix` provides Caddy-based static file serving for dashboards. The consumer passes in dashboard derivations and gets bookmarkable URLs.

```nix
agentplot.dashboards = {
  enable = true;
  domain = "dashboards.swancloud.net";
  sites = {
    fleet = fleet-dashboard;              # derivation with index.html
    capabilities = capabilities-dashboard; # derivation with index.html
  };
};
```

The module generates Caddy virtual host config with `file_server` directives — one route per site (e.g., `dashboards.swancloud.net/fleet/`, `dashboards.swancloud.net/capabilities/`). It references `config.caddy-cloudflare.tls` from agentplot-kit for TLS, matching the pattern used by all other agentplot server roles.

**Alternative: leave serving to the consumer.** Rejected because dashboard serving is generic infrastructure that belongs in the framework. Making it first-class means every consumer gets bookmarkable dashboard URLs without hand-writing Caddy config.

**Alternative: one subdomain per dashboard.** Rejected in favor of path-based routing under a single domain — simpler DNS and cert management, and the dashboards are closely related.

## Risks / Trade-offs

**[Evaluation cost]** Serialization requires evaluating HM config, which is heavier than reading inventory data. → Mitigation: This already happens during `nixos-rebuild`; serialization just reads already-evaluated options. No extra evaluation passes.

**[Option path coupling]** Serialization reads `programs.claude-code.mcpServers` etc. If HM module option paths change, serialization breaks. → Mitigation: These paths are defined by agentplot-kit's HM modules which we control. Version together.

**[CLI tool extraction]** Unlike MCP servers and skills which have dedicated option paths, CLI tools are mixed into `home.packages` with non-agentplot packages. → Mitigation: Use a convention — agentplot.nix can track which packages it contributes via an internal option, or we extract package names matching known patterns. Design decision to resolve during implementation.

**[Assembly documentation]** The multi-machine assembly is the most likely point of confusion for consumers. → Mitigation: Include a complete example in the lib function documentation and in the spec.
