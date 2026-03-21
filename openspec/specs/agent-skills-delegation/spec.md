## ADDED Requirements

### Requirement: HM module import for agent-skills-nix
The agentplot adapter (`modules/agentplot.nix`) SHALL import the `agent-skills-nix` Home Manager module so that `programs.agent-skills` options are defined in the HM evaluation context before any service module sets them.

#### Scenario: agent-skills options available after import
- **WHEN** the agentplot HM module composition includes a service that sets `programs.agent-skills` attributes
- **THEN** Nix evaluation SHALL succeed without "undefined option" errors for `programs.agent-skills.sources`, `programs.agent-skills.skills.explicit`, and `programs.agent-skills.targets`

### Requirement: Path-based source registration
When a linkding client has `agent-skills.enabled = true`, the client HM module SHALL register a source named `"agentplot-linkding"` with `type = "path"` pointing to the service's `skills/` directory.

#### Scenario: Source registered for single client
- **WHEN** one linkding client has `agent-skills.enabled = true`
- **THEN** `programs.agent-skills.sources."agentplot-linkding"` SHALL be set with `type = "path"` and `path` pointing to the linkding `skills/` directory

#### Scenario: Source registered for multiple clients
- **WHEN** two linkding clients both have `agent-skills.enabled = true`
- **THEN** `programs.agent-skills.sources."agentplot-linkding"` SHALL be set exactly once (shared source, not duplicated per client)

### Requirement: Explicit skill with packages and transform
Each client with `agent-skills.enabled = true` SHALL register a `skills.explicit.<cliName>` entry that includes the CLI wrapper package and a transform function that substitutes `linkding-cli` with the client's `cliName`.

#### Scenario: Single client explicit skill
- **WHEN** a linkding client named `personal` with `cliName = "linkding"` has `agent-skills.enabled = true`
- **THEN** `programs.agent-skills.skills.explicit."linkding"` SHALL exist with `source = "agentplot-linkding"`, `packages` containing the CLI wrapper, and `transform` replacing `"linkding-cli"` with `"linkding"` in skill content

#### Scenario: Multi-client explicit skills with different names
- **WHEN** client `personal` has `cliName = "linkding"` and client `biz` has `cliName = "linkding-biz"`, both with `agent-skills.enabled = true`
- **THEN** both `programs.agent-skills.skills.explicit."linkding"` and `programs.agent-skills.skills.explicit."linkding-biz"` SHALL exist, each with their own transform and CLI wrapper package

### Requirement: Claude target distribution
When `agent-skills.enabled = true`, the client HM module SHALL set `programs.agent-skills.targets.claude.enable = true` so skills are distributed to Claude Code's skill directory.

#### Scenario: Claude target enabled
- **WHEN** any linkding client has `agent-skills.enabled = true`
- **THEN** `programs.agent-skills.targets.claude.enable` SHALL be `true`

### Requirement: Phase 1 / Phase 2 mutual exclusion
When a client has `agent-skills.enabled = true`, the Phase 1 skill path (`programs.claude-code.skills.<cliName>`) SHALL NOT be set for that client, preventing duplicate skill writes to the same output path.

#### Scenario: Phase 2 suppresses Phase 1
- **WHEN** a client has both `claude-code.skill.enabled = true` and `agent-skills.enabled = true`
- **THEN** `programs.claude-code.skills.<cliName>` SHALL NOT be set by that client's HM module
- **AND** `programs.agent-skills.skills.explicit.<cliName>` SHALL be set instead

#### Scenario: Phase 1 active when Phase 2 disabled
- **WHEN** a client has `claude-code.skill.enabled = true` and `agent-skills.enabled = false`
- **THEN** `programs.claude-code.skills.<cliName>` SHALL be set as before (no behavioral change)

### Requirement: Evaluation test coverage
A Nix evaluation test SHALL verify the agent-skills delegation pipeline evaluates correctly, covering source registration, explicit skill definition, target enablement, and multi-client coexistence.

#### Scenario: Test passes for single client
- **WHEN** `nix-instantiate --eval` runs the agent-skills delegation test with one client configured
- **THEN** evaluation SHALL succeed and assertions SHALL pass

#### Scenario: Test passes for multi-client
- **WHEN** `nix-instantiate --eval` runs the agent-skills delegation test with two clients having different `cliName` values
- **THEN** evaluation SHALL succeed and assertions SHALL pass for both clients' skill entries
