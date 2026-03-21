## ADDED Requirements

### Requirement: Single-client MCP delegation generates correct config
When a single client has `claude-code.mcp.enabled = true`, the generated HM module SHALL include a `programs.claude-code.mcpServers` entry keyed by the client's `name`, with `command` pointing to the per-client CLI wrapper and `args` containing `["mcp"]`.

#### Scenario: Single client with MCP enabled
- **WHEN** a client named "personal" with `name = "linkding"` has `claude-code.mcp.enabled = true`
- **THEN** `programs.claude-code.mcpServers.linkding` SHALL exist with `args = ["mcp"]` and `command` containing the wrapper path

#### Scenario: MCP disabled by default
- **WHEN** a client is configured without setting `claude-code.mcp.enabled`
- **THEN** `programs.claude-code.mcpServers` SHALL NOT contain an entry for that client

### Requirement: Multi-client MCP delegation produces distinct entries
When multiple clients each have MCP enabled, each SHALL produce a distinct `mcpServers` entry keyed by its own `name`, and all entries SHALL coexist without conflict in the merged HM module.

#### Scenario: Two clients with MCP enabled
- **WHEN** client "personal" (`name = "linkding"`) and client "work" (`name = "linkding-biz"`) both have `claude-code.mcp.enabled = true`
- **THEN** `programs.claude-code.mcpServers` SHALL contain both `linkding` and `linkding-biz` entries with distinct `command` paths

### Requirement: Per-profile MCP delegation generates profile-scoped config
When a client has `claude-code.profiles.<profile>.mcp.enabled = true`, the generated HM module SHALL include `programs.claude-code.profiles.<profile>.mcpServers` with the client's MCP config, without affecting the default profile.

#### Scenario: Profile-specific MCP enabled
- **WHEN** a client has `claude-code.profiles.business.mcp.enabled = true` and `claude-code.mcp.enabled = false`
- **THEN** `programs.claude-code.profiles.business.mcpServers.linkding` SHALL exist
- **THEN** `programs.claude-code.mcpServers` SHALL NOT contain the client's entry

### Requirement: Evaluation test is runnable with nix-instantiate
The MCP delegation test SHALL be a pure Nix evaluation test runnable via `nix-instantiate --eval`, following the pattern established by `tests/hmModules-composition.nix`.

#### Scenario: Test passes on valid config
- **WHEN** `nix-instantiate --eval tests/mcp-delegation.nix` is run
- **THEN** the command SHALL exit 0 and output a PASS string
