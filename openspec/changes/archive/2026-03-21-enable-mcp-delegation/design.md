## Context

The linkding clanService client role already has complete MCP delegation infrastructure: option declarations (`claude-code.mcp.enabled`, `claude-code.profiles.<name>.mcp.enabled`), HM module wiring (`programs.claude-code.mcpServers.<cliName>`), and per-client config generation (`mcpConfig` with command/args/env). However, the MCP config points to `<cliWrapper> mcp` — a subcommand that doesn't exist. The CLI (`linkding-cli`) is a `writeShellApplication` wrapper around restish that forwards all arguments to `restish linkding "$@"`.

## Goals / Non-Goals

**Goals:**
- Implement a working `mcp` subcommand in the linkding-cli wrapper that speaks MCP stdio transport
- Expose linkding bookmark CRUD, search, tag management, and bundle operations as MCP tools
- Keep the implementation as a shell wrapper — no compiled language, consistent with existing CLI approach
- Add Nix evaluation tests for MCP delegation config generation
- Verify multi-client and per-profile MCP scenarios

**Non-Goals:**
- Replacing the restish-based CLI — the `mcp` subcommand is additive
- Implementing MCP over HTTP/SSE transport — stdio only (Claude Code expectation)
- Adding MCP support to Phase 2 integrations (agent-deck, openclaw, etc.)
- Authentication changes — reuse existing `LINKDING_API_TOKEN` mechanism

## Decisions

### 1. MCP server implementation: `mcp-proxy` with OpenAPI spec

**Decision:** Use `mcp-proxy` (or equivalent OpenAPI-to-MCP bridge) to auto-generate MCP tools from the existing `openapi.json` spec, wrapped in a shell script.

**Rationale:** The linkding-cli already ships an `openapi.json` (572 lines, 15 endpoints). Rather than hand-coding MCP tool handlers, an OpenAPI-to-MCP bridge produces correct tool schemas automatically and stays in sync with API changes.

**Alternative considered:** Hand-written Python/Node MCP server. Rejected — adds a runtime dependency and duplicates what the OpenAPI spec already describes.

**Alternative considered:** Using restish output as MCP tool responses. Rejected — restish outputs human-formatted text, not structured JSON suitable for MCP tool results.

### 2. CLI routing: intercept `mcp` before restish dispatch

**Decision:** Add an `if [[ "$1" == "mcp" ]]; then ... fi` guard at the top of the linkding-cli wrapper, before the restish exec. When invoked with `mcp`, launch the MCP server process instead of restish.

**Rationale:** Minimal change to existing wrapper. The `mcp` subcommand is a distinct mode of operation (long-running stdio server vs one-shot CLI). Intercepting before restish avoids restish trying to interpret "mcp" as an API path.

### 3. MCP config env vars: align with existing wrapper

**Decision:** The `mcpConfig.env` currently sets `LINKDING_API_TOKEN_FILE` and `LINKDING_BASE_URL`. The MCP subcommand will read the token from file (matching the cliWrapper pattern that does `cat ${tokenPath}`) and use these env vars directly.

**Rationale:** The per-client cliWrapper already reads the token from file and exports it. The MCP subcommand inherits this environment, so no additional secret handling is needed.

### 4. Test approach: Nix evaluation test for config shape

**Decision:** Add a new `tests/mcp-delegation.nix` that evaluates a mock client role config and asserts the HM module produces correct `programs.claude-code.mcpServers` entries. Test single-client, multi-client, and per-profile scenarios.

**Rationale:** Follows the existing pattern in `tests/hmModules-composition.nix`. Evaluation tests are fast, pure, and don't require a running linkding instance.

## Risks / Trade-offs

- **[mcp-proxy availability]** If `mcp-proxy` isn't in nixpkgs, we need to package it or find an alternative. → Mitigation: Fall back to a minimal Python MCP server using `mcp` PyPI package (available in nixpkgs as `python3Packages.mcp`).
- **[OpenAPI spec drift]** If `openapi.json` diverges from the actual linkding API version deployed. → Mitigation: The spec is already vendored and used by restish — same source of truth.
- **[MCP tool granularity]** Auto-generated tools from OpenAPI may expose too many or oddly-named tools. → Mitigation: Can curate tool list in a follow-up; initial implementation exposes all endpoints.
