## Context

The linkding clanService client role already defines `claude-tools.enabled` (default `false`) and conditional logic that writes to `programs.claude-tools.skills-installer.skillsByClient.claude-code.${cliName} = "symlink"`. This code path has never been exercised in inventory or validated by tests. The `programs.claude-tools` option is expected to be provided by an upstream HM module (e.g., `claude-plugins-nix`), and `skillsByClient` uses `attrsOf (attrsOf str)` semantics to merge contributions from multiple services.

The existing `tests/hmModules-composition.nix` validates that two mock clanServices can accumulate HM modules via the agentplot adapter, but it does not exercise the `claude-tools` option path.

## Goals / Non-Goals

**Goals:**
- Enable `claude-tools.enabled = true` for at least one linkding client in the test harness
- Validate that a single client produces the correct `skillsByClient` attribute
- Validate that two clients (e.g., `linkding` and `linkding-biz`) merge without conflict
- Extend the Nix evaluation test to assert `skillsByClient` output structure
- Confirm that cross-service merge works (two different clanServices both contributing to `skillsByClient`)

**Non-Goals:**
- Implementing the upstream `programs.claude-tools` HM module (assumed to exist or be mocked)
- Testing the actual skill installation runtime (symlink creation on disk)
- Modifying the linkding service's `claude-tools` option definition or delegation logic
- Enabling claude-tools in production inventory (this validates the pattern only)

## Decisions

### Mock `programs.claude-tools` in test harness
The test will define a minimal `programs.claude-tools.skills-installer.skillsByClient` option stub using `attrsOf (attrsOf str)` with `mkMerge` semantics. This avoids a dependency on the full `claude-plugins-nix` flake input during testing.

**Alternative considered:** Import the real `claude-plugins-nix` module. Rejected because it adds a heavy dependency to the test and couples test validity to an external flake.

### Extend existing composition test rather than create a new file
The existing `tests/hmModules-composition.nix` already validates multi-service HM module accumulation. Adding `claude-tools` assertions here keeps all composition tests co-located and exercises the full delegation chain.

**Alternative considered:** Separate test file `tests/claude-tools-delegation.nix`. Rejected because the composition test already has the scaffolding; a separate file would duplicate setup.

### Test with two linkding clients plus a second mock service
This validates both intra-service merge (two linkding clients) and inter-service merge (linkding + another service contributing to `skillsByClient`). The second mock service can be minimal — just enough to write a `skillsByClient` entry.

## Risks / Trade-offs

- **Mock drift**: The `programs.claude-tools` mock may diverge from the real module's option types. → Mitigated by keeping the mock minimal (`attrsOf (attrsOf str)`) matching the documented contract.
- **Test doesn't cover runtime**: Nix evaluation tests validate config structure but not actual symlink creation. → Acceptable; runtime testing is a separate concern requiring a full system build.
- **`mkMerge` semantics assumption**: We assume `attrsOf` merges deeply by default (NixOS module system behavior). → This is well-established NixOS module system behavior; the test itself will confirm it.
