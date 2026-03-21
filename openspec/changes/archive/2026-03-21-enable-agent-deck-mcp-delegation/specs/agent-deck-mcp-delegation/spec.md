## ADDED Requirements

### Requirement: Single-client agent-deck MCP entry generation

When a linkding client has `agent-deck.mcp.enabled = true`, the HM module delegation SHALL produce a `programs.agent-deck.mcps.<clientName>` entry containing `command`, `args`, and `env` keys matching the client's CLI wrapper and connection details.

#### Scenario: Single client with agent-deck MCP enabled

- **WHEN** a linkding client named "linkding" is configured with `agent-deck.mcp.enabled = true`, `base_url = "https://links.example.com"`, and `name = "linkding"`
- **THEN** `programs.agent-deck.mcps.linkding` SHALL exist with:
  - `command` containing the path to the linkding CLI wrapper binary
  - `args` equal to `["mcp"]`
  - `env.LINKDING_BASE_URL` equal to `"https://links.example.com"`
  - `env.LINKDING_API_TOKEN_FILE` pointing to the clan vars token path

#### Scenario: Client with agent-deck MCP disabled

- **WHEN** a linkding client is configured with `agent-deck.mcp.enabled = false` (the default)
- **THEN** `programs.agent-deck.mcps` SHALL NOT contain an entry for that client

### Requirement: Multi-client agent-deck MCP composition

When multiple linkding clients each have `agent-deck.mcp.enabled = true`, their MCP entries SHALL merge without conflict into `programs.agent-deck.mcps`, producing one distinct entry per client.

#### Scenario: Two clients with agent-deck MCP enabled

- **WHEN** two linkding clients are configured:
  - Client "personal" with `name = "linkding"`, `base_url = "https://links.example.com"`, `agent-deck.mcp.enabled = true`
  - Client "biz" with `name = "linkding-biz"`, `base_url = "https://links-biz.example.com"`, `agent-deck.mcp.enabled = true`
- **THEN** `programs.agent-deck.mcps` SHALL contain exactly two entries: `linkding` and `linkding-biz`
- **AND** each entry SHALL have distinct `command` paths and `env.LINKDING_BASE_URL` values matching their respective configurations

#### Scenario: Mixed enablement across clients

- **WHEN** client "personal" has `agent-deck.mcp.enabled = true` and client "biz" has `agent-deck.mcp.enabled = false`
- **THEN** `programs.agent-deck.mcps` SHALL contain only the `linkding` entry from "personal"

### Requirement: Agent-deck MCP config structure compatibility

The generated `programs.agent-deck.mcps` entries SHALL produce valid agent-deck TOML config when processed by the `nix-agent-deck` HM module. Each entry MUST contain the keys that agent-deck expects for stdio-based MCP servers.

#### Scenario: Config structure matches agent-deck expectations

- **WHEN** a linkding client's agent-deck MCP entry is generated
- **THEN** the entry SHALL be an attrset with:
  - `command` (string): absolute Nix store path to the CLI wrapper
  - `args` (list of strings): MCP subcommand arguments
  - `env` (attrset of strings): environment variables for the MCP process
- **AND** the structure SHALL be compatible with `nix-agent-deck`'s `mcps` option type (`attrsOf (attrsOf anything)`)
