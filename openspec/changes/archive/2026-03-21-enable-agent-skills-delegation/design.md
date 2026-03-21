## Context

The linkding clanService client role already has Phase 2 stubs for `programs.agent-skills` delegation (lines 319-331 of `services/linkding/default.nix`). The `agent-skills-nix` flake input is declared but not wired into outputs. The Phase 1 path (`programs.claude-code.skills`) is active and working. Both paths can emit skill config simultaneously when their respective flags are true, risking duplicate/conflicting writes.

Currently, `agent-skills-nix` (Kyure-A/agent-skills-nix) provides a Home Manager module with `programs.agent-skills` options for source registration, explicit skill definition (with packages and transform), and target-based distribution (e.g., `targets.claude.enable`).

## Goals / Non-Goals

**Goals:**
- Wire `agent-skills-nix` HM module into flake outputs so `programs.agent-skills` options resolve
- Validate the full delegation pipeline: source → explicit skill → transform → target distribution
- Confirm multi-client coexistence (two clients with different CLI names share the same source)
- Prevent Phase 1 / Phase 2 conflicts when both flags are true
- Add Nix evaluation tests covering the agent-skills delegation path

**Non-Goals:**
- Wiring the other Phase 2 stubs (`programs.agent-deck`, `programs.openclaw`, `programs.claude-tools`)
- Modifying the `agent-skills-nix` upstream module itself
- Changing the Phase 1 path behavior — it remains the default
- Runtime/integration testing against a live linkding instance

## Decisions

### 1. Import `agent-skills-nix` HM module via agentplot adapter

The `agent-skills-nix` HM module must be imported into the Home Manager evaluation context. The agentplot adapter (`modules/agentplot.nix`) already accumulates HM modules from services. The agent-skills-nix module will be added as a base import alongside the per-service modules, so `programs.agent-skills` options are defined before any service tries to set them.

**Alternative considered:** Having each service import it individually — rejected because multiple services using agent-skills would cause duplicate module imports and option conflicts.

### 2. Guard Phase 1 and Phase 2 as mutually exclusive per-client

When `agent-skills.enabled = true`, the Phase 1 `programs.claude-code.skills` assignment for that client should be suppressed. This prevents two modules writing the same skill content to overlapping paths. The guard will be `lib.mkIf (!clientSettings.agent-skills.enabled)` around the Phase 1 block.

**Alternative considered:** Allowing both paths to coexist and relying on `lib.mkMerge` — rejected because the same skill name written by both paths would produce an option conflict error (both set the same attr without `lib.mkForce`).

### 3. Test with nix-instantiate eval, not full NixOS build

Evaluation tests (`nix-instantiate --eval`) are fast and don't require building packages. The test will mock the `programs.agent-skills` option interface (sources, skills.explicit, targets) and assert that the linkding client role produces the expected attribute structure when `agent-skills.enabled = true`.

**Alternative considered:** Full `nix build` test with actual HM activation — rejected as too heavyweight for CI and requiring actual package builds.

### 4. Multi-client test: two clients with different cliName values

The test will configure two clients (e.g., `personal` with cliName `linkding` and `biz` with cliName `linkding-biz`). Both should register distinct `skills.explicit` entries referencing the same `sources."agentplot-linkding"` path, each with their own transform replacing `linkding-cli` with their respective cliName.

## Risks / Trade-offs

- **[Risk] `agent-skills-nix` option interface may differ from what the stubs expect** → Mitigation: Read the actual module options from the flake input during implementation; adapt the stub code if the interface has changed.
- **[Risk] Mutual exclusion breaks users who want both paths** → Mitigation: This is intentional — running both paths for the same client produces duplicate config. Users choose one phase per client. Document this in the option description.
- **[Trade-off] Mocking agent-skills options in tests vs importing the real module** → We mock to avoid network fetches and flake lock changes in CI. The trade-off is less fidelity, mitigated by the real module being tested via `nix flake check` when the lock is updated.
