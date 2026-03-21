## Why

The linkding clanService client role has Claude Code MCP delegation infrastructure (options, HM module wiring) but it's never been enabled or tested. The MCP config references a `linkding-cli mcp` subcommand that doesn't exist — the CLI is a restish wrapper with no MCP server mode. Enabling MCP delegation lets Claude Code interact with linkding bookmarks directly through the Model Context Protocol, complementing the existing skill-based approach.

## What Changes

- Implement an MCP server subcommand in linkding-cli that bridges the linkding REST API to MCP stdio transport
- Enable `claude-code.mcp.enabled = true` as a tested, documented capability
- Enable per-profile MCP via `claude-code.profiles.<name>.mcp.enabled`
- Add a Nix evaluation test verifying MCP server entries appear in the generated HM config
- Verify multi-client scenarios: two clients each producing distinct MCP server entries

## Capabilities

### New Capabilities
- `linkding-mcp-server`: MCP stdio server implementation for linkding-cli, exposing bookmark CRUD, tag management, and search as MCP tools
- `mcp-delegation-test`: Nix evaluation tests verifying MCP server config generation for single-client, multi-client, and per-profile scenarios

### Modified Capabilities

## Impact

- `services/linkding/packages/linkding-cli/` — New MCP server subcommand added to the CLI wrapper
- `services/linkding/default.nix` — No structural changes; existing MCP delegation code is already correct
- `tests/` — New evaluation test for MCP delegation
- Dependencies: May need an MCP server library/tool as a new flake input or inline implementation
