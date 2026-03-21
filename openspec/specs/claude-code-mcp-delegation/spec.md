## ADDED Requirements

### Requirement: Default MCP delegation produces correct mcpServers config
When a linkding client has `claude-code.mcp.enabled = true`, the generated HM module SHALL include a `programs.claude-code.mcpServers.<cliName>` entry with `command` pointing to the client CLI wrapper, `args` set to `["mcp"]`, and `env` containing `LINKDING_API_TOKEN_FILE` and `LINKDING_BASE_URL`.

#### Scenario: Single client with MCP enabled
- **WHEN** a linkding client named "personal" has `claude-code.mcp.enabled = true` and `base_url = "https://linkding.example.com"`
- **THEN** the HM module SHALL produce `programs.claude-code.mcpServers.linkding-personal` with `args = ["mcp"]` and `env.LINKDING_BASE_URL = "https://linkding.example.com"` and `env.LINKDING_API_TOKEN_FILE` pointing to the secret path

#### Scenario: MCP disabled by default
- **WHEN** a linkding client named "personal" has `claude-code.mcp.enabled` at its default value (`false`)
- **THEN** the HM module SHALL NOT produce any `programs.claude-code.mcpServers` entry for that client

### Requirement: Profile-scoped MCP delegation produces correct per-profile config
When a linkding client has `claude-code.profiles.<name>.mcp.enabled = true`, the generated HM module SHALL include `programs.claude-code.profiles.<name>.mcpServers.<cliName>` with the same MCP config structure.

#### Scenario: Profile-specific MCP enabled
- **WHEN** a linkding client named "work" has `claude-code.profiles.business.mcp.enabled = true` and `base_url = "https://linkding.work.com"`
- **THEN** the HM module SHALL produce `programs.claude-code.profiles.business.mcpServers.linkding-work` with `args = ["mcp"]` and `env.LINKDING_BASE_URL = "https://linkding.work.com"`

#### Scenario: Default and profile MCP both enabled
- **WHEN** a client has both `claude-code.mcp.enabled = true` and `claude-code.profiles.business.mcp.enabled = true`
- **THEN** the HM module SHALL produce entries in both `programs.claude-code.mcpServers` and `programs.claude-code.profiles.business.mcpServers`

### Requirement: Multi-client MCP coexistence
When multiple linkding clients each have MCP enabled, the generated HM modules SHALL produce distinct `mcpServers` entries keyed by their respective CLI names without conflicts.

#### Scenario: Two clients with MCP enabled
- **WHEN** client "personal" (base_url "https://linkding.home.com") and client "work" (base_url "https://linkding.work.com") both have `claude-code.mcp.enabled = true`
- **THEN** the merged HM config SHALL contain both `programs.claude-code.mcpServers.linkding-personal` and `programs.claude-code.mcpServers.linkding-work` with their respective URLs

### Requirement: Nix evaluation test validates MCP delegation
A Nix evaluation test SHALL exist that exercises the MCP delegation logic and asserts correctness of the generated config.

#### Scenario: Test passes for correct delegation
- **WHEN** `nix-instantiate --eval tests/mcp-delegation.nix` is run
- **THEN** the evaluation SHALL succeed (exit code 0), confirming all MCP delegation assertions pass
