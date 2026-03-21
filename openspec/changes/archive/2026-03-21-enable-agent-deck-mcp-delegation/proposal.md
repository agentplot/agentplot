## Why

The linkding clanService client role already implements `agent-deck.mcp.enabled` as a Phase 2 option with full HM module delegation code, but it has never been activated or tested end-to-end. Enabling this unlocks agent-deck session management for linkding MCP servers, allowing AI coding agents to interact with linkding bookmarks through agent-deck's session-aware MCP infrastructure.

## What Changes

- Enable `agent-deck.mcp.enabled = true` in linkding client inventory configuration
- Add a Nix evaluation test verifying that `programs.agent-deck.mcps` generates correct entries when the option is enabled
- Verify multi-client composition: two linkding clients each producing distinct agent-deck MCP entries without conflict
- Validate the generated MCP config structure matches what `nix-agent-deck` expects (command, args, env)

## Capabilities

### New Capabilities

- `agent-deck-mcp-delegation`: End-to-end enablement and testing of agent-deck MCP entry generation from linkding clanService client role, including single-client activation, multi-client composition, and config structure validation.

### Modified Capabilities

(none)

## Impact

- **services/linkding/default.nix**: No code changes expected; the delegation logic already exists. This change activates and validates it.
- **tests/**: New evaluation test(s) for agent-deck MCP delegation alongside existing HM module composition test.
- **nix-agent-deck input**: Dependency on `programs.agent-deck.mcps` option interface being stable.
- **Inventory**: Consumers enabling `agent-deck.mcp.enabled = true` will get MCP entries in their agent-deck config.
