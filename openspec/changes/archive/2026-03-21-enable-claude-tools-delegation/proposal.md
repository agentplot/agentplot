## Why

The linkding clanService client role defines `claude-tools.enabled` as an option that registers skills via `programs.claude-tools.skills-installer.skillsByClient`, but this path has never been tested end-to-end. Without validation, we cannot confirm that the marketplace skill reference is correctly generated, that multiple clients merge properly via `attrsOf`, or that the delegation composes across multiple clanServices.

## What Changes

- Enable `claude-tools.enabled = true` in inventory for a linkding client instance
- Validate that `skillsByClient.claude-code.<cliName>` produces the correct marketplace skill reference (`"symlink"` mode)
- Add a multi-client test: two linkding clients (e.g., `linkding` and `linkding-biz`) both contributing to `skillsByClient`
- Verify that `attrsOf` merge semantics work correctly when multiple clanServices contribute to the same `skillsByClient` attribute set
- Add a Nix evaluation test to assert the composed output

## Capabilities

### New Capabilities
- `claude-tools-delegation`: Covers the claude-tools skill registration via `skillsByClient`, including single-client correctness, multi-client merge, and cross-service composition

### Modified Capabilities

## Impact

- `services/linkding/default.nix` — client role's `claude-tools` conditional block exercised
- `tests/` — new or extended evaluation test asserting `skillsByClient` output
- Inventory configuration patterns — documented enablement of `claude-tools.enabled`
- No breaking changes; existing behavior is unaffected when `claude-tools.enabled` remains `false` (the default)
