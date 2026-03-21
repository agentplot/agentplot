## ADDED Requirements

### Requirement: Client interface options
The client role interface SHALL expose the following options:
- `domain`: `lib.types.str` — FQDN of the qmd server (e.g., `qmd.swancloud.net`)
- `port`: `lib.types.port` with default `8423` — qmd server port
- `claude-code.mcp.enabled`: `lib.types.bool` with default `false` — enable MCP server in default Claude Code profile
- `claude-code.profiles`: `lib.types.attrsOf profileSubmodule` with default `{}` — per-profile MCP configuration
- `agent-deck.mcp.enabled`: `lib.types.bool` with default `false` — enable agent-deck MCP entry

#### Scenario: Minimal client configuration
- **WHEN** a client role is configured with `domain = "qmd.swancloud.net"` and `claude-code.mcp.enabled = true`
- **THEN** the MCP endpoint is configured pointing to `https://qmd.swancloud.net`

#### Scenario: Multiple profile configuration
- **WHEN** a client role is configured with per-profile MCP settings
- **THEN** each enabled profile receives the qmd MCP server configuration

### Requirement: Claude Code MCP HTTP endpoint delegation
The client role SHALL configure Claude Code MCP servers using HTTP transport type pointing to `https://<domain>/mcp`. The MCP config SHALL use the `url` field (not `command`/`args`) for Streamable HTTP transport.

#### Scenario: Default profile MCP enabled
- **WHEN** `claude-code.mcp.enabled` is `true`
- **THEN** the Home Manager module adds a `qmd` MCP server entry with `url = "https://<domain>/mcp"` to the default Claude Code profile

#### Scenario: Per-profile MCP enabled
- **WHEN** `claude-code.profiles.<name>.mcp.enabled` is `true`
- **THEN** the Home Manager module adds a `qmd` MCP server entry to that specific profile

#### Scenario: MCP disabled
- **WHEN** `claude-code.mcp.enabled` is `false` and no profiles enable MCP
- **THEN** no qmd MCP server entries are added to any Claude Code configuration

### Requirement: Agent-deck MCP delegation
The client role SHALL configure agent-deck MCP servers using HTTP transport when `agent-deck.mcp.enabled` is `true`.

#### Scenario: Agent-deck MCP enabled
- **WHEN** `agent-deck.mcp.enabled` is `true`
- **THEN** the Home Manager module adds a `qmd` MCP entry with HTTP URL to agent-deck configuration

### Requirement: HM module delegation
The client role SHALL produce a Home Manager module that accumulates into `agentplot.hmModules.qmd-client` following the standard delegation pattern.

#### Scenario: HM module registered
- **WHEN** the client role is configured on a machine
- **THEN** the module is available at `agentplot.hmModules.qmd-client` and wired into the user's Home Manager config

### Requirement: Cross-platform client support
The client role SHALL work on both NixOS (`nixosModule`) and Darwin (`darwinModule`) systems, since MCP configuration is Home Manager-only with no system-level dependencies.

#### Scenario: Darwin client
- **WHEN** the client role is applied to a Darwin machine
- **THEN** the Home Manager module configures MCP endpoints identically to NixOS
