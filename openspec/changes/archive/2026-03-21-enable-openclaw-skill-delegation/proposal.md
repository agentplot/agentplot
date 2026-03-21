## Why

The linkding clanService client role defines `openclaw.skill.enabled` and delegation code that appends to `programs.openclaw.skills`, but this path has never been tested end-to-end. Without verification, enabling this option in a fleet inventory could silently fail or produce incorrect skill entries, blocking OpenClaw adoption across clanServices.

## What Changes

- Enable `openclaw.skill.enabled = true` in inventory for a client and verify the skill entry is appended to `programs.openclaw.skills` with correct `name`, `mode`, and `content` fields.
- Add a Nix evaluation test covering single-client and multi-client OpenClaw skill delegation.
- Verify that list-typed `programs.openclaw.skills` from multiple clanServices composes without deduplication issues through the HM module delegation adapter.

## Capabilities

### New Capabilities
- `openclaw-skill-delegation`: Verified end-to-end OpenClaw skill delegation from clanService client roles, including multi-client composition and correct skill entry structure.

### Modified Capabilities
<!-- None — no existing spec-level requirements are changing. -->

## Impact

- `services/linkding/default.nix` — client role OpenClaw skill wiring (already implemented, needs testing)
- `tests/` — new evaluation test for OpenClaw skill delegation and multi-client composition
- `modules/agentplot.nix` — HM delegation adapter (verified, not modified)
