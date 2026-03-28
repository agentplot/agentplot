## ADDED Requirements

### Requirement: Serialization option exists
The `agentplot.nix` module SHALL expose a `config.agentplot.serialization` option that evaluates to a JSON-serializable attrset containing the agentplot-relevant Home Manager config for the configured user.

#### Scenario: Module with services configured
- **WHEN** `agentplot.user` is set and `agentplot.hmModules` contains service client entries
- **THEN** `config.agentplot.serialization` evaluates to an attrset with keys: `machine`, `user`, `mcpServers`, `skills`, `cliTools`, `agentDeckMcps`, `profiles`

#### Scenario: Module with no user configured
- **WHEN** `agentplot.user` is null
- **THEN** `config.agentplot.serialization` evaluates to null

#### Scenario: Module with user but no services
- **WHEN** `agentplot.user` is set but `agentplot.hmModules` is empty
- **THEN** `config.agentplot.serialization` evaluates to an attrset with empty collections for each capability type

### Requirement: Machine and user identification
The serialization SHALL include `machine` (from `config.networking.hostName`) and `user` (from `config.agentplot.user`) fields to identify the source when multiple machines are assembled.

#### Scenario: Machine name extracted
- **WHEN** serialization is evaluated on a machine with `networking.hostName = "mac-studio"`
- **THEN** `config.agentplot.serialization.machine` equals `"mac-studio"`

### Requirement: MCP server extraction
The serialization SHALL include all Claude Code MCP servers from the evaluated `home-manager.users.<user>.programs.claude-code.mcpServers` config, preserving transport type and URL.

#### Scenario: Multiple MCP servers from different services
- **WHEN** linkding-biz (HTTP) and ogham-mcp (SSE) client roles are configured
- **THEN** `serialization.mcpServers` contains entries for both with their respective type and URL

### Requirement: Skills extraction
The serialization SHALL include all agent-skills source names from `home-manager.users.<user>.programs.agent-skills.sources` as a list of strings.

#### Scenario: Skills from multiple services
- **WHEN** linkding, subcog, and obsidian client roles are configured
- **THEN** `serialization.skills` contains the source names contributed by each service

### Requirement: CLI tools extraction
The serialization SHALL include names of agentplot-contributed CLI tool packages. Non-agentplot packages in `home.packages` SHALL NOT be included.

#### Scenario: CLI tools from client roles
- **WHEN** linkding-biz and subcog-personal client roles contribute CLI wrappers
- **THEN** `serialization.cliTools` contains `"linkding-biz"` and `"subcog-personal"` (or their wrapper names)

### Requirement: Agent-deck MCP extraction
The serialization SHALL include agent-deck MCP entries from `home-manager.users.<user>.programs.agent-deck.mcps`.

#### Scenario: Agent-deck MCPs configured
- **WHEN** subcog and ogham-mcp client roles contribute agent-deck MCP entries
- **THEN** `serialization.agentDeckMcps` contains entries for both

### Requirement: Claude Code profiles extraction
The serialization SHALL include Claude Code profile definitions from `home-manager.users.<user>.programs.claude-code.profiles`, including which MCP servers each profile references.

#### Scenario: Multiple profiles configured
- **WHEN** business and personal Claude Code profiles are defined with different MCP server sets
- **THEN** `serialization.profiles` contains both profiles with their respective MCP server lists

### Requirement: JSON serializable output
All values in the serialization attrset SHALL be JSON-serializable (strings, lists, attrsets of primitives). Derivations, functions, and NixOS module metadata (`_file`, `imports`) SHALL NOT appear in the output.

#### Scenario: Serialization passes builtins.toJSON
- **WHEN** `config.agentplot.serialization` is passed to `builtins.toJSON`
- **THEN** it produces valid JSON without evaluation errors
