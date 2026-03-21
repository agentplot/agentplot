### Requirement: Client role definition
The gno clanService SHALL define a `roles.client` entry providing MCP endpoint configuration and HM module delegation for darwin and NixOS machines.

#### Scenario: Client role available in clanService
- **WHEN** the gno clanService is evaluated
- **THEN** `roles.client` SHALL be present with a description indicating MCP endpoint configuration

### Requirement: Client role interface options
The client role SHALL expose interface options for: `domain` (str, FQDN of the gno server), `port` (int, default 8422), `claude-code.mcp.enabled` (bool, default false), and `agent-deck.mcp.enabled` (bool, default false).

#### Scenario: Minimal client configuration
- **WHEN** a client instance is configured with `domain = "gno.swancloud.net"` and `claude-code.mcp.enabled = true`
- **THEN** the MCP endpoint SHALL be configured as `https://gno.swancloud.net` for claude-code

### Requirement: Singleton client pattern
The client role SHALL use a singleton pattern (no `clients` attrset). Interface options SHALL be flat on the role, not nested under named client keys.

#### Scenario: Single endpoint configuration
- **WHEN** the client role is configured
- **THEN** exactly one MCP endpoint SHALL be derived from the domain and port settings

### Requirement: MCP endpoint configuration for claude-code
When `claude-code.mcp.enabled` is true, the client role SHALL configure a Claude Code MCP server entry named `gno` with `url` type pointing to the Streamable HTTP endpoint at `https://<domain>/mcp`.

#### Scenario: Claude Code MCP server configured
- **WHEN** `claude-code.mcp.enabled = true` and `domain = "gno.swancloud.net"`
- **THEN** `programs.claude-code.mcpServers.gno` SHALL be set with `url = "https://gno.swancloud.net/mcp"`

### Requirement: MCP endpoint configuration for agent-deck
When `agent-deck.mcp.enabled` is true, the client role SHALL configure an agent-deck MCP entry named `gno` with the Streamable HTTP endpoint URL.

#### Scenario: Agent-deck MCP entry configured
- **WHEN** `agent-deck.mcp.enabled = true` and `domain = "gno.swancloud.net"`
- **THEN** `programs.agent-deck.mcps.gno` SHALL be set with the HTTP endpoint URL

### Requirement: HM module delegation
The client role SHALL accumulate its Home Manager module via `agentplot.hmModules.gno-client`, following the delegation pattern used by other clanServices.

#### Scenario: HM module registered
- **WHEN** the client role is activated on a darwin or NixOS machine
- **THEN** `agentplot.hmModules.gno-client` SHALL contain the client's HM module

### Requirement: Cross-platform support
The client role SHALL produce both `nixosModule` and `darwinModule` outputs from the same module definition, enabling use on both NixOS VMs and darwin workstations.

#### Scenario: Darwin and NixOS modules identical
- **WHEN** the client role's `perInstance` is evaluated
- **THEN** both `nixosModule` and `darwinModule` SHALL reference the same module function
