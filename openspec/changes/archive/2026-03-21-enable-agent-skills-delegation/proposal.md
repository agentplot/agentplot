## Why

The linkding clanService client role has Phase 2 stubs for `programs.agent-skills` delegation (via `agent-skills-nix`), but this path has never been tested end-to-end. The `agent-skills-nix` flake input is declared but not wired into flake outputs. Enabling this delegation layer decouples skill definitions from specific agent platforms, allowing skills to target multiple consumers without per-platform config knowledge.

## What Changes

- Wire `agent-skills-nix` HM module into the flake outputs so `programs.agent-skills` options are available
- Enable `agent-skills.enabled = true` for linkding client instances in inventory
- Verify path-based source registration (`sources."agentplot-linkding"`) resolves correctly
- Verify `skills.explicit` with packages (CLI wrapper) and transform (CLI name substitution) works
- Verify `targets.claude.enable` distributes the skill to Claude Code's config
- Test multi-client scenario: two explicit skills with different rename values (e.g., `linkding` and `linkding-biz`)
- Resolve potential conflicts between Phase 1 (`programs.claude-code.skills`) and Phase 2 (`programs.agent-skills`) writing to the same skill path
- Add evaluation tests for the agent-skills delegation path

## Capabilities

### New Capabilities
- `agent-skills-delegation`: End-to-end agent-skills-nix integration — source registration, explicit skill definition with packages and transform, Claude target distribution, and multi-client coexistence

### Modified Capabilities

_(none — no existing spec-level requirements are changing)_

## Impact

- **`flake.nix`**: Must import and expose `agent-skills-nix` HM module in outputs
- **`services/linkding/default.nix`**: May need guards to prevent Phase 1 / Phase 2 conflict when both paths are active; currently both are always emitted when their respective flags are true
- **`tests/`**: New evaluation test(s) for agent-skills delegation path
- **Dependencies**: `agent-skills-nix` flake input (already declared, needs lock resolution and output wiring)
