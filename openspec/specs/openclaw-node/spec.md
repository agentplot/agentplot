## Purpose

OpenClaw node role providing remote gateway connection with per-node plugin configuration, supporting both NixOS and Darwin.

## Requirements

### Requirement: OpenClaw node role provides remote gateway connection
The openclaw node role SHALL configure `programs.openclaw` with `gateway.mode = "remote"`, reading the server's domain and gateway token from the inventory. Plugins and bundled plugins are configurable per-node.

#### Scenario: Node references server settings from inventory
- **WHEN** a node is configured alongside a server in the same inventory
- **THEN** the node SHALL derive `wss://${serverDomain}` and gateway token path from the server role's machines

#### Scenario: Node has its own plugin configuration
- **WHEN** `plugins` or `bundledPlugins` are set on the node
- **THEN** those SHALL be passed through to `programs.openclaw.bundledPlugins` and `instances.default.plugins`
