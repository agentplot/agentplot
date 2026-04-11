# packages/

Dashboard packages for cross-machine capability visualization. These are **not** service CLI packages (those live in `services/<name>/packages/`).

## capabilities-dashboard/

HTML dashboard showing MCP servers, skills, CLI tools, and agent-deck configs across all machines. Built from `agentplot.serialization` snapshots.

- `default.nix` — `mkCapabilitiesDashboard { pkgs, capabilitiesSerialization }` → derivation with `index.html`
- `inventory.nix` — `mkCapabilitiesInventory` → JSON inventory file for programmatic use

The consuming inventory (swancloud) collects per-machine serialization blobs and passes them in.

## fleet-dashboard/

Similar dashboard for fleet-level inventory views.

- `default.nix` — `mkFleetDashboard { pkgs, inventorySerialization }`
- `inventory.nix` — `mkFleetInventory` → JSON inventory
