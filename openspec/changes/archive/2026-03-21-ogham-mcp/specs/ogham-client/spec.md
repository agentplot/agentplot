## ADDED Requirements

### Requirement: Client role interface options
The client role SHALL expose a `clients` attrset where each client entry has options: `name` (string, identifier), `url` (string, SSE endpoint URL), `claude-code.mcp.enabled` (bool, default false), `claude-code.profiles` (attrsOf profileSubmodule with `mcp.enabled`), and `agent-deck.mcp.enabled` (bool, default false).

#### Scenario: Minimal client configuration
- **WHEN** a client entry specifies only `name` and `url`
- **THEN** `claude-code.mcp.enabled` SHALL default to false, `agent-deck.mcp.enabled` SHALL default to false, and `claude-code.profiles` SHALL default to empty

#### Scenario: Client with profile-scoped MCP
- **WHEN** a client entry has `claude-code.profiles.work.mcp.enabled = true`
- **THEN** the MCP server entry SHALL be added to the `work` profile configuration

### Requirement: MCP endpoint configuration
Each enabled client SHALL produce an MCP server configuration with `url` set to the SSE endpoint. The MCP config SHALL use the `sse` transport type.

#### Scenario: Claude Code MCP entry
- **WHEN** `claude-code.mcp.enabled` is true for a client
- **THEN** `programs.claude-code.mcpServers.<name>` SHALL contain the SSE URL pointing to the ogham-mcp server

#### Scenario: Agent-deck MCP entry
- **WHEN** `agent-deck.mcp.enabled` is true for a client
- **THEN** `programs.agent-deck.mcps.<name>` SHALL contain the SSE URL pointing to the ogham-mcp server

### Requirement: HM module delegation
The client role SHALL populate `agentplot.hmModules` with one entry per client, keyed as `ogham-mcp-<clientName>`, containing a deferred HM module that configures MCP endpoints.

#### Scenario: HM module is registered
- **WHEN** a client named "default" is configured
- **THEN** `agentplot.hmModules."ogham-mcp-default"` SHALL exist and be a valid deferred HM module

#### Scenario: Multiple clients produce separate HM modules
- **WHEN** clients "work" and "personal" are configured
- **THEN** `agentplot.hmModules."ogham-mcp-work"` and `agentplot.hmModules."ogham-mcp-personal"` SHALL both exist

### Requirement: Profile-based MCP configuration
The client role SHALL support per-profile MCP configuration, allowing different Claude Code profiles to enable/disable the ogham-mcp MCP server independently.

#### Scenario: Profile enables MCP
- **WHEN** client "default" has `claude-code.profiles.research.mcp.enabled = true`
- **THEN** `programs.claude-code.profiles.research.mcpServers.ogham-mcp` SHALL contain the SSE endpoint configuration

#### Scenario: Profile disabled by default
- **WHEN** a profile exists but `mcp.enabled` is not set
- **THEN** the ogham-mcp MCP server SHALL NOT be added to that profile

### Requirement: Vars generator for API key (client-side)
Each client SHALL have a vars generator for the ogham-mcp API key (if the server requires authentication), stored as a secret file with appropriate ownership for the agentplot user.

#### Scenario: API key secret is prompted
- **WHEN** the vars generator for client "default" runs
- **THEN** it SHALL prompt for the API key and store it at `files.api-key.path` with `secret = true` and owner set to `config.agentplot.user`

### Requirement: Skill document
The service SHALL include a `skills/SKILL.md` file describing ogham-mcp capabilities for agent consumption, with YAML frontmatter containing `name`, `description`, and `env` fields.

#### Scenario: Skill document exists
- **WHEN** the service directory is inspected
- **THEN** `services/ogham-mcp/skills/SKILL.md` SHALL exist with valid YAML frontmatter

#### Scenario: Skill is installed when claude-code skill is enabled
- **WHEN** a client has `claude-code.skill.enabled = true`
- **THEN** `programs.claude-code.skills.<name>` SHALL contain the skill content with the client name substituted

### Requirement: Flake wiring
The service SHALL be registered in `flake.nix` as `clan.modules.ogham-mcp`.

#### Scenario: Flake output exists
- **WHEN** `nix flake show` is run
- **THEN** `clan.modules.ogham-mcp` SHALL be present in the outputs
