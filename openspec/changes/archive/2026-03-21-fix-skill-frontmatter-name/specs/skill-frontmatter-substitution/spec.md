## ADDED Requirements

### Requirement: Skill frontmatter name matches client identity
The `clientSkill` derivation in `mkClientConfig` SHALL produce a SKILL.md where the frontmatter `name:` field equals the client's `cliName` value.

#### Scenario: Single default client
- **WHEN** a client is configured with `name = "linkding"`
- **THEN** the generated skill frontmatter contains `name: linkding`

#### Scenario: Named alternate client
- **WHEN** a client is configured with `name = "linkding-biz"`
- **THEN** the generated skill frontmatter contains `name: linkding-biz`

#### Scenario: Body CLI references remain correct
- **WHEN** a client is configured with `name = "linkding-biz"`
- **THEN** the generated skill body references `linkding-biz` (not `linkding-cli`) in all command examples

### Requirement: Phase 2 agent-skills transform matches primary substitution
The `transform` function in the `programs.agent-skills` configuration SHALL apply the same frontmatter name substitution as the primary `clientSkill` derivation.

#### Scenario: Agent-skills transform rewrites frontmatter name
- **WHEN** the agent-skills transform processes SKILL.md content for a client with `name = "linkding-biz"`
- **THEN** the transformed content contains `name: linkding-biz` in the frontmatter
