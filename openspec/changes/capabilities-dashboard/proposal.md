## Why

The fleet dashboard shows which services are deployed to which machines, but there's no visibility into what the evaluated Home Manager config actually produces for each user. After mkClientTooling merges skills, MCP servers, CLI tools, and agent-deck MCPs across multiple services, the only way to verify the result is to inspect each machine manually. A capabilities dashboard provides a QA-level cross-machine view of exactly what each user gets — which MCP servers are active, which skills are installed, which CLI tools are available, and how Claude Code profiles partition them.

## What Changes

- Add an `agentplot.serialization` option to `modules/agentplot.nix` that extracts the evaluated HM config (MCP servers, skills, CLI tools, agent-deck MCPs, Claude Code profiles) into a JSON-serializable attribute set
- Add `lib.mkCapabilitiesDashboard` and `lib.mkCapabilitiesInventory` functions (mirroring the fleet dashboard pattern) that take an assembled `capabilitiesSerialization` and produce an HTML dashboard / JSON file
- Create the dashboard HTML — a self-contained SPA showing a machine × user × profile capability matrix
- Add `agentplot.dashboards` NixOS/Darwin module for first-class static dashboard serving via Caddy — consumers pass in dashboard derivations and get bookmarkable URLs
- The **consuming repo** (e.g., swancloud) is responsible for assembling `capabilitiesSerialization` by collecting `config.agentplot.serialization` from each machine's evaluated config and bundling them into one structure. This is a multi-machine, multi-user assembly step that differs from the fleet dashboard's single `inventorySerialization` blob (which clan provides pre-assembled).

## Capabilities

### New Capabilities
- `agentplot-serialization`: Module option in `agentplot.nix` that extracts evaluated HM config into a serializable structure (MCP servers, skills, CLI tools, profiles, agent-deck MCPs) per machine/user
- `capabilities-dashboard`: Library functions (`mkCapabilitiesDashboard`, `mkCapabilitiesInventory`) and HTML SPA that render the cross-machine capability matrix from assembled serialization data
- `dashboard-serving`: NixOS/Darwin module (`agentplot.dashboards`) that serves static dashboard HTML via Caddy file_server, providing bookmarkable URLs for fleet and capabilities dashboards

### Modified Capabilities

(none)

## Impact

- `modules/agentplot.nix` — new `agentplot.serialization` option added
- `packages/` — new `capabilities-dashboard/` directory (HTML template + Nix builders)
- `flake.nix` — new `lib.mkCapabilitiesDashboard` and `lib.mkCapabilitiesInventory` exports
- `modules/` — new `dashboards.nix` module for Caddy-based static serving
- `flake.nix` — new `nixosModules.dashboards` and `darwinModules.dashboards` exports
- Consumers (swancloud) will need to:
  1. Collect `config.agentplot.serialization` from each machine's NixOS/Darwin config
  2. Assemble into `capabilitiesSerialization = { machines = { <name> = <serialization>; ... }; }`
  3. Call `mkCapabilitiesDashboard { pkgs; capabilitiesSerialization; }` in their flake outputs
  4. Enable `agentplot.dashboards` and pass dashboard derivations for bookmarkable serving
