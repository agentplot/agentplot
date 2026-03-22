## ADDED Requirements

### Requirement: Tana service is client-only with no server role
The tana clanService SHALL define only `roles.client` with no server or guest role. The service uses `mkClientTooling` for its client role, following the same pattern as obsidian and email.

#### Scenario: Service definition has only client role
- **WHEN** the tana clanService is imported
- **THEN** `roles` SHALL contain only `client` and SHALL NOT contain `server`, `guest`, or `host`

### Requirement: Tana client role bundles tana-export skill
The tana client role SHALL declare `capabilities.skills` with a tana-export SKILL.md describing Tana knowledge management export operations.

#### Scenario: Skill delegated to claude-code
- **WHEN** a tana client enables `claude-code.skill.enabled = true`
- **THEN** `programs.claude-code.skills` SHALL contain a tana-export skill entry with substituted client name

### Requirement: Tana service naming accommodates future growth
The service SHALL be named `tana` (not `tana-export`) so that future capabilities (e.g., Tana API integration, sync) can be added under the same service without renaming.

#### Scenario: Service name is generic
- **WHEN** the tana clanService is defined
- **THEN** `manifest.name` SHALL be "tana" and the service directory SHALL be `services/tana/`
