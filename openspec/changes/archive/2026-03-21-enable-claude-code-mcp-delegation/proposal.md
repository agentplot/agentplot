## Why

The linkding clanService client role already defines `claude-code.mcp.enabled` and `claude-code.profiles.<name>.mcp.enabled` options with full delegation code, but MCP delegation has never been enabled or tested end-to-end. Without testing, there's no confidence the generated `programs.claude-code.mcpServers` config is correct or that the MCP server actually connects to linkding.

## What Changes

- Enable `claude-code.mcp.enabled = true` in a client configuration and verify the generated MCP server config is correct
- Enable `claude-code.profiles.business.mcp.enabled = true` for profile-specific MCP and verify profile-scoped config generation
- Add a Nix evaluation test that asserts the MCP delegation produces expected `programs.claude-code.mcpServers` and profile-scoped MCP entries
- Test multi-client scenario: two linkding clients each producing their own MCP entry in Claude Code config

## Capabilities

### New Capabilities
- `claude-code-mcp-delegation`: MCP server delegation from linkding client role to Claude Code Home Manager config, including default and profile-scoped MCP entries

### Modified Capabilities

## Impact

- `services/linkding/default.nix` — no code changes expected; this is validation of existing delegation logic
- `tests/` — new evaluation test for MCP delegation correctness
- If bugs are found during testing, fixes will be in the client role's `mkClientConfig` or `cc.hmModule` sections
