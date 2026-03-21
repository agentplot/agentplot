## Context

The linkding clanService client role already implements Claude Code MCP delegation in `services/linkding/default.nix` (lines 268–316). The `mkClientConfig` function builds an `mcpConfig` object and wires it into `programs.claude-code.mcpServers` (default) and `programs.claude-code.profiles.<name>.mcpServers` (per-profile) via `lib.mkMerge` and `lib.mkIf` guards. This code has never been enabled or tested end-to-end.

The existing test (`tests/hmModules-composition.nix`) validates multi-service HM module composition but does not exercise MCP-specific paths.

## Goals / Non-Goals

**Goals:**
- Validate that `claude-code.mcp.enabled = true` produces correct `programs.claude-code.mcpServers` entries
- Validate that `claude-code.profiles.<name>.mcp.enabled = true` produces correct profile-scoped MCP entries
- Validate multi-client MCP coexistence (two clients, two MCP entries)
- Add a Nix evaluation test that asserts MCP delegation correctness
- Fix any bugs discovered during testing

**Non-Goals:**
- Runtime integration testing (actually connecting to a linkding server)
- Changes to the MCP delegation architecture
- Adding MCP support to other services

## Decisions

### Test approach: Nix evaluation test
**Decision**: Use `nix-instantiate --eval` tests (same pattern as `tests/hmModules-composition.nix`) to assert the shape of generated HM config.

**Rationale**: Nix evaluation tests are fast, deterministic, and don't require a running linkding instance. They verify the Nix expression logic that builds `mcpServers` config. Runtime MCP connectivity is a separate concern (non-goal).

**Alternative considered**: NixOS VM test (`nixos/tests`). Too heavyweight for validating config generation — we're testing Nix expressions, not service behavior.

### Test file location
**Decision**: `tests/mcp-delegation.nix` — dedicated test file for MCP delegation logic.

**Rationale**: Keeps MCP-specific assertions separate from the existing composition smoke test. The existing test validates module coexistence; this test validates MCP config correctness.

### Test assertions
**Decision**: Evaluate the HM modules with mock client configs and assert:
1. `programs.claude-code.mcpServers` contains the expected keys and values when `mcp.enabled = true`
2. `programs.claude-code.profiles.business.mcpServers` contains the expected entries when `profiles.business.mcp.enabled = true`
3. Two clients produce two distinct MCP entries without conflicts

## Risks / Trade-offs

- **[Risk] Delegation code may have bugs only visible at HM evaluation time** → Mitigation: The eval test will import actual HM module types to catch type errors
- **[Risk] mcpConfig `command` path depends on Nix store hash** → Mitigation: Assert on attribute existence and structure, not exact store paths
- **[Risk] Runtime MCP connectivity not tested** → Accepted: Runtime testing is out of scope; we test config generation correctness
