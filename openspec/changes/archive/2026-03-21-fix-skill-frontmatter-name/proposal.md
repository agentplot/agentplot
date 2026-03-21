## Why

When the linkding clanService client role generates per-client skills (e.g., `linkding` and `linkding-biz`), the SKILL.md frontmatter `name:` field is not updated to match the client name. Both skills output `name: linkding` even though the biz skill correctly references `linkding-biz` CLI in the body. This causes skill identity collisions — agents cannot distinguish between instances by frontmatter metadata.

## What Changes

- Extend `replaceStrings` in `mkClientConfig` to also substitute the frontmatter `name:` field, replacing `name: linkding` with `name: <cliName>` for each client instance
- Apply the same fix to the Phase 2 `agent-skills` transform function for consistency

## Capabilities

### New Capabilities

- `skill-frontmatter-substitution`: Ensure per-client skill generation produces correct frontmatter metadata (name field) matching the client identity

### Modified Capabilities

(none — no existing specs)

## Impact

- `services/linkding/default.nix` — `clientSkill` derivation (line ~262) and `agent-skills` transform (line ~327)
- All linkding client instances will get correctly named skills after rebuild
- No breaking changes — only corrects previously incorrect output
