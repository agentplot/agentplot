## ADDED Requirements

### Requirement: Client role definition
The service SHALL define a `client` role that configures MCP HTTP endpoint access to a subcog server instance.

#### Scenario: Client role exists
- **WHEN** the service is inspected
- **THEN** it SHALL have a `roles.client` with a description indicating it connects to a remote subcog server

### Requirement: Client interface options
The client role interface SHALL expose: `domain` (string, required — FQDN of the subcog server), `claude-code.mcp.enabled` (bool, default false), and `agent-deck.mcp.enabled` (bool, default false).

#### Scenario: Domain is required
- **WHEN** a client instance is configured without `domain`
- **THEN** evaluation SHALL fail with a missing option error

#### Scenario: MCP flags default to false
- **WHEN** a client instance is configured with only `domain`
- **THEN** `claude-code.mcp.enabled` and `agent-deck.mcp.enabled` SHALL default to false

### Requirement: JWT token management
The client role SHALL reference the shared JWT secret from `clan.core.vars` to authenticate against the subcog server.

#### Scenario: Token file accessible
- **WHEN** the client role is applied
- **THEN** it SHALL reference the vars file for `subcog-jwt-secret` with `owner` set to `config.agentplot.user`

### Requirement: MCP HTTP endpoint configuration
When `claude-code.mcp.enabled` is true, the client role SHALL configure a Claude Code MCP server entry with `type = "http"` pointing to `https://<domain>/mcp` with the JWT token in the Authorization header.

#### Scenario: Claude Code MCP configured
- **WHEN** `claude-code.mcp.enabled = true` and `domain = "subcog.swancloud.net"`
- **THEN** the HM module SHALL add an MCP server named `subcog` with `url = "https://subcog.swancloud.net/mcp"` and JWT bearer token auth

#### Scenario: Claude Code MCP not configured when disabled
- **WHEN** `claude-code.mcp.enabled = false`
- **THEN** no Claude Code MCP server entry SHALL be added

### Requirement: Agent-deck MCP configuration
When `agent-deck.mcp.enabled` is true, the client role SHALL configure an agent-deck MCP server entry pointing to the subcog HTTP endpoint.

#### Scenario: Agent-deck MCP configured
- **WHEN** `agent-deck.mcp.enabled = true` and `domain = "subcog.swancloud.net"`
- **THEN** the HM module SHALL configure agent-deck MCP with the subcog HTTP endpoint and JWT auth

### Requirement: HM module delegation
The client role SHALL produce a Home Manager module accumulated into `agentplot.hmModules.subcog-<instanceName>`, following the delegation pattern from `modules/agentplot.nix`.

#### Scenario: HM module accumulated
- **WHEN** a client instance named `default` is applied
- **THEN** `agentplot.hmModules.subcog-default` SHALL contain the client's Home Manager module

#### Scenario: Platform-specific modules
- **WHEN** the client role is applied
- **THEN** it SHALL provide both `nixosModule` and `darwinModule` in `perInstance`

### Requirement: Agent skill file
The service SHALL include a `skills/SKILL.md` file documenting subcog's MCP tools for agent consumption.

#### Scenario: SKILL.md exists with correct frontmatter
- **WHEN** `services/subcog/skills/SKILL.md` is read
- **THEN** it SHALL have YAML frontmatter with `name: subcog` and `description` referencing persistent memory and hybrid search

#### Scenario: SKILL.md documents core tool categories
- **WHEN** `services/subcog/skills/SKILL.md` is read
- **THEN** it SHALL document tool categories including memory storage, retrieval, search, entity management, and namespace operations

### Requirement: Skill installation
When `claude-code.mcp.enabled` is true, the client role SHALL install the SKILL.md as a Claude Code skill.

#### Scenario: Skill file installed
- **WHEN** `claude-code.mcp.enabled = true`
- **THEN** the HM module SHALL install the subcog SKILL.md into the Claude Code skills directory
