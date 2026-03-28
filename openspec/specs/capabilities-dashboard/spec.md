## Purpose

Library functions and HTML SPA for cross-machine capability views, enabling visual inspection and comparison of agentplot-managed capabilities across a fleet of machines.

## Requirements

### Requirement: mkCapabilitiesDashboard library function
The flake SHALL export `lib.mkCapabilitiesDashboard` accepting `{ pkgs, capabilitiesSerialization }` and returning a derivation containing `index.html` — a self-contained SPA with the capabilities data embedded as JSON.

#### Scenario: Dashboard build from assembled serialization
- **WHEN** consumer calls `mkCapabilitiesDashboard { pkgs; capabilitiesSerialization = { machines = { mac-studio = <serialization>; openclaw = <serialization>; }; }; }`
- **THEN** the result is a derivation with `$out/index.html` containing a complete, dependency-free HTML page with the serialization data embedded

### Requirement: mkCapabilitiesInventory library function
The flake SHALL export `lib.mkCapabilitiesInventory` accepting `{ pkgs, capabilitiesSerialization }` and returning a derivation containing the serialization as a plain JSON file.

#### Scenario: JSON inventory export
- **WHEN** consumer calls `mkCapabilitiesInventory { pkgs; capabilitiesSerialization; }`
- **THEN** the result is a JSON file parseable by standard tools (jq, Python, etc.)

### Requirement: Multi-machine assembly input format
`capabilitiesSerialization` SHALL accept a `machines` attrset where each key is a machine name and each value is that machine's `config.agentplot.serialization` output. The consumer is responsible for assembling this from their evaluated NixOS/Darwin configurations.

#### Scenario: Consumer assembles from multiple machine configs
- **WHEN** consumer builds `capabilitiesSerialization` by collecting `config.agentplot.serialization` from three machines (NixOS server, Darwin laptop, Darwin desktop)
- **THEN** `mkCapabilitiesDashboard` renders all three machines in the dashboard

#### Scenario: Single machine
- **WHEN** consumer provides `capabilitiesSerialization` with only one machine
- **THEN** the dashboard renders correctly with one machine card

### Requirement: Machine card view
The dashboard SHALL display a card for each machine showing the machine name, user, and all capabilities grouped by type (MCP servers, skills, CLI tools, agent-deck MCPs).

#### Scenario: Machine with full capabilities
- **WHEN** a machine has MCP servers, skills, CLI tools, and agent-deck MCPs configured
- **THEN** the card shows all four groups with their entries listed

#### Scenario: Machine with partial capabilities
- **WHEN** a machine has skills but no MCP servers or CLI tools
- **THEN** the card shows only the skills group (empty groups are omitted or shown as empty)

### Requirement: Profile-aware display
The dashboard SHALL show Claude Code profiles and which MCP servers each profile includes. This allows verifying that profile-based partitioning (e.g., business vs personal) is correct.

#### Scenario: Machine with multiple profiles
- **WHEN** a machine's serialization includes `business` and `personal` profiles with different MCP server sets
- **THEN** the dashboard shows each profile and its MCP servers, making the difference visible

### Requirement: Cross-machine comparison
The dashboard SHALL provide a way to compare capabilities across machines — either via a matrix view (rows = capabilities, columns = machines) or side-by-side machine cards.

#### Scenario: Comparing two machines
- **WHEN** dashboard shows mac-studio and openclaw
- **THEN** user can see that mac-studio has subcog-personal MCP but openclaw does not (or vice versa)

### Requirement: Self-contained HTML
The dashboard HTML SHALL have no external dependencies (no CDN links, no fetch calls). All CSS and JavaScript SHALL be inline. The JSON data SHALL be embedded in the HTML at build time via placeholder substitution.

#### Scenario: Offline viewing
- **WHEN** user opens the built `index.html` in a browser without network access
- **THEN** the dashboard renders completely

### Requirement: Dark theme consistent with fleet dashboard
The dashboard SHALL use the same dark theme color palette as the fleet dashboard (GitHub-style: `--bg: #0d1117`, `--surface: #161b22`, etc.).

#### Scenario: Visual consistency
- **WHEN** user opens the capabilities dashboard alongside the fleet dashboard
- **THEN** both dashboards share the same visual style

### Requirement: Assembly documentation
The lib functions SHALL include clear documentation (in description strings and/or comments) explaining:
1. That `capabilitiesSerialization` must be assembled by the consumer from per-machine configs
2. How to collect `config.agentplot.serialization` from NixOS and Darwin configurations
3. A complete example showing the assembly pattern for a mixed NixOS + Darwin fleet

#### Scenario: New consumer onboarding
- **WHEN** a developer reads the `mkCapabilitiesDashboard` function signature and comments
- **THEN** they understand they must build `capabilitiesSerialization.machines` from their evaluated configs, with a concrete code example to follow
