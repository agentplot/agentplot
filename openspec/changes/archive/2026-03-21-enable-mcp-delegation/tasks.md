## 1. MCP Server Implementation

- [x] 1.1 Add MCP server runtime dependency (python3 with mcp package or mcp-proxy) to linkding-cli `runtimeInputs` in `services/linkding/packages/linkding-cli/default.nix`
- [x] 1.2 Create MCP server script that bridges linkding REST API to MCP stdio transport, reading `LINKDING_BASE_URL` and `LINKDING_API_TOKEN` from environment
- [x] 1.3 Add `mcp` subcommand routing in linkding-cli wrapper: intercept `mcp` as first argument before restish dispatch
- [x] 1.4 Verify `nix build .#linkding-cli` succeeds with MCP dependencies included

## 2. MCP Delegation Tests

- [x] 2.1 Create `tests/mcp-delegation.nix` evaluation test with mock client role config asserting single-client MCP generates correct `programs.claude-code.mcpServers` entry
- [x] 2.2 Add multi-client test case: two clients with distinct names both producing MCP entries
- [x] 2.3 Add per-profile test case: `claude-code.profiles.business.mcp.enabled = true` generates profile-scoped config
- [x] 2.4 Add negative test case: MCP disabled by default produces no mcpServers entry
- [x] 2.5 Verify `nix-instantiate --eval tests/mcp-delegation.nix` passes

## 3. Verification

- [x] 3.1 Run `nix flake check` to verify no regressions
- [x] 3.2 Run existing `nix-instantiate --eval tests/hmModules-composition.nix` to verify no composition breakage
