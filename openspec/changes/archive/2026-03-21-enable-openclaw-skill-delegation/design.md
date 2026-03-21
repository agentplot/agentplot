## Context

The linkding clanService client role already implements `openclaw.skill.enabled` (defaulting to `false`) with delegation code that appends a skill entry to `programs.openclaw.skills`. The HM module delegation adapter (`modules/agentplot.nix`) wires accumulated `agentplot.hmModules` into a single user's Home Manager config. However, the OpenClaw skill path has never been tested end-to-end — neither for a single client nor for multi-client composition.

The existing `tests/hmModules-composition.nix` smoke test validates that two mock services can write to `agentplot.hmModules` without conflict, but does not exercise `programs.openclaw.skills` list merging.

## Goals / Non-Goals

**Goals:**
- Verify the existing OpenClaw skill delegation code produces correct skill entries (name, mode, content)
- Verify multi-client composition: two clients with `openclaw.skill.enabled = true` both contribute to `programs.openclaw.skills` without conflicts or deduplication
- Add a Nix evaluation test that catches regressions in this path

**Non-Goals:**
- Modifying the OpenClaw skill entry structure (mode, content format)
- Adding new clanServices beyond linkding for testing
- Runtime testing of OpenClaw itself (this is Nix-evaluation-level verification only)
- Changing the `programs.openclaw` module definition (owned by nix-openclaw)

## Decisions

### Test approach: Nix evaluation test (not integration test)

Use `nix-instantiate --eval` style testing, similar to `tests/hmModules-composition.nix`. This evaluates the module composition at Nix level without requiring a running system.

**Rationale**: The existing test infrastructure uses this pattern. The question being answered is "does the Nix module produce the right attribute values?" — not "does OpenClaw work at runtime." Nix eval tests are fast, deterministic, and run in CI without system dependencies.

**Alternative considered**: NixOS VM test (`nixos/tests`). Rejected because the skill delegation is purely a module-composition concern — there's nothing to test at runtime that isn't covered by checking the evaluated config attributes.

### Test structure: standalone test file

Create `tests/openclaw-skill-delegation.nix` as a standalone evaluation test, following the same pattern as `hmModules-composition.nix`.

**Rationale**: Keeps tests focused and independently runnable. The HM composition test validates the adapter plumbing; this test validates the OpenClaw-specific skill wiring through it.

### Mock `programs.openclaw` module in test

The test needs a minimal mock of the `programs.openclaw` module that defines `programs.openclaw.skills` as a list option. This avoids importing `nix-openclaw` as a test dependency.

**Rationale**: The test validates that linkding's client role produces the correct list entries. It doesn't need the real OpenClaw module — just the option type it writes to.

## Risks / Trade-offs

- **[Risk] Mock drift**: The mock `programs.openclaw.skills` option type may diverge from the real `nix-openclaw` module → **Mitigation**: Keep the mock minimal (just `lib.types.listOf lib.types.attrs`) and document that it mirrors the real option. If `nix-openclaw` changes the type, the real fleet build will catch it.
- **[Risk] No runtime coverage**: Evaluation tests confirm config shape but not runtime behavior → **Mitigation**: Acceptable for Phase 2. Runtime verification belongs to fleet-level integration tests when OpenClaw is fully deployed.
