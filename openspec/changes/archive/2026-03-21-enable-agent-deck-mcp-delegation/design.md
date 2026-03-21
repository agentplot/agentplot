## Context

The linkding clanService client role (line 199 of `services/linkding/default.nix`) already declares `agent-deck.mcp.enabled` as a Phase 2 option. The delegation code at line 333–335 writes to `programs.agent-deck.mcps.${cliName}` with a `{ command, args, env }` attrset. The upstream `nix-agent-deck` HM module (`programs.agent-deck.mcps`) is freeform (`attrsOf (attrsOf anything)`) and generates `[mcps.<name>]` sections in `~/.agent-deck/config.toml` as TOML.

The existing HM composition test (`tests/hmModules-composition.nix`) validates `claude-tools` delegation but has no coverage for `agent-deck`.

## Goals / Non-Goals

**Goals:**
- Activate `agent-deck.mcp.enabled = true` for linkding clients and verify the generated config is correct
- Add Nix evaluation tests that prove single-client and multi-client `programs.agent-deck.mcps` composition works
- Validate the generated TOML structure matches what agent-deck expects: `[mcps.<name>]` with `command`, `args`, and `env` keys

**Non-Goals:**
- Modifying the existing delegation code in `services/linkding/default.nix` (it already works; we're testing it)
- Runtime/integration testing with a live agent-deck process or linkding server
- Enabling `agent-deck.mcp.enabled` by default (it stays opt-in)
- Adding agent-deck delegation to other clanServices (scope is linkding only)

## Decisions

### D1: Test via Nix evaluation, not integration

We test by evaluating mock HM modules through `lib.evalModules` and asserting on the resulting `config.programs.agent-deck.mcps` attrset — the same pattern used in the existing `hmModules-composition.nix` test.

**Rationale:** This validates the Nix-level wiring without requiring a running system, agent-deck binary, or linkding instance. The existing test pattern is proven and fast (`nix-instantiate --eval`).

**Alternative considered:** Building the full derivation and inspecting the generated `config.toml` file. Rejected because it requires a full Nix build, is slower, and the TOML generation is already tested upstream in `nix-agent-deck`'s own checks (`mcp-definitions`).

### D2: Separate test file for agent-deck delegation

Create `tests/agent-deck-mcp-delegation.nix` rather than extending `hmModules-composition.nix`.

**Rationale:** The existing test focuses on HM module accumulation and `claude-tools` merge. Agent-deck MCP delegation is a distinct concern with its own option stubs. Keeping it separate makes failures easier to diagnose and avoids bloating the existing test.

### D3: Stub only `programs.agent-deck.mcps` option

The test stubs only the `programs.agent-deck.mcps` option definition (matching the freeform `attrsOf (attrsOf anything)` type from `nix-agent-deck`). We don't need to stub the full `programs.agent-deck` module since we're only asserting on the mcps attrset.

**Rationale:** Minimal stubbing keeps the test focused. The full module's TOML generation is tested upstream.

## Risks / Trade-offs

- **[Upstream schema drift]** → The `nix-agent-deck` mcps option is freeform (`attrsOf (attrsOf anything)`), so there's no compile-time enforcement of the `command`/`args`/`env` shape. If agent-deck changes its expected config format, our tests won't catch it. **Mitigation:** Pin `nix-agent-deck` via flake lock; periodically verify against upstream checks.

- **[Stub divergence]** → Our test stubs `programs.agent-deck.mcps` independently from the real module. If `nix-agent-deck` changes the option type, our stub may not reflect that. **Mitigation:** Use the same type (`attrsOf (attrsOf anything)`) and add a comment noting the upstream source.

- **[No runtime validation]** → We validate Nix evaluation output but not that agent-deck can actually use the generated config to connect to linkding. **Mitigation:** This is explicitly a non-goal; runtime testing is a future concern.
