### Requirement: Single-client OpenClaw skill entry
When a linkding client has `openclaw.skill.enabled = true`, the evaluated HM module SHALL produce exactly one entry in `programs.openclaw.skills` with `name` matching the client's CLI name, `mode` set to `"symlink"`, and `content` containing the client-specific skill markdown.

#### Scenario: Single client with openclaw skill enabled
- **WHEN** a linkding client named "personal" has `openclaw.skill.enabled = true` and `name = "linkding"`
- **THEN** `programs.openclaw.skills` SHALL contain exactly one entry with `name = "linkding"`, `mode = "symlink"`, and `content` containing a non-empty string with the skill markdown

#### Scenario: Client with openclaw skill disabled
- **WHEN** a linkding client named "personal" has `openclaw.skill.enabled = false`
- **THEN** `programs.openclaw.skills` SHALL be empty or not set for that client's HM module

### Requirement: Multi-client OpenClaw skill composition
When multiple linkding clients each have `openclaw.skill.enabled = true`, the HM module delegation adapter SHALL merge all skill entries into a single `programs.openclaw.skills` list without deduplication or conflict.

#### Scenario: Two clients with different CLI names
- **WHEN** client "personal" has `name = "linkding"` and `openclaw.skill.enabled = true`, AND client "biz" has `name = "linkding-biz"` and `openclaw.skill.enabled = true`
- **THEN** `programs.openclaw.skills` SHALL contain exactly two entries: one with `name = "linkding"` and one with `name = "linkding-biz"`, each with `mode = "symlink"` and distinct non-empty `content`

#### Scenario: Mixed enabled and disabled clients
- **WHEN** client "personal" has `openclaw.skill.enabled = true` AND client "biz" has `openclaw.skill.enabled = false`
- **THEN** `programs.openclaw.skills` SHALL contain exactly one entry from the "personal" client

### Requirement: Skill content reflects client CLI name
Each OpenClaw skill entry's `content` field SHALL contain skill markdown with CLI references replaced by the client's configured `name` value, not the generic template name.

#### Scenario: Client-specific CLI name in skill content
- **WHEN** a client has `name = "linkding-biz"` and `openclaw.skill.enabled = true`
- **THEN** the skill entry's `content` SHALL reference `linkding-biz` (not `linkding-cli`) in its body text
