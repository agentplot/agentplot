## ADDED Requirements

### Requirement: Email service is client-only with generic interface
The email clanService SHALL define only `roles.client` with no server role. The module SHALL be generic — no IMAP/SMTP credentials, account names, or server addresses. Account-specific configuration belongs in the consuming inventory (swancloud).

#### Scenario: Service definition has only client role
- **WHEN** the email clanService is imported
- **THEN** `roles` SHALL contain only `client` and SHALL NOT contain `server`

### Requirement: Email client role installs himalaya package
The email client role SHALL declare `capabilities.cli` with the himalaya email client package, generating per-client CLI wrappers.

#### Scenario: CLI wrapper generated per client
- **WHEN** an email client is configured with `name = "email"`
- **THEN** a CLI wrapper named "email" SHALL be available in the user's PATH, wrapping the himalaya binary

### Requirement: Email client role bundles email-management skill
The email client role SHALL declare `capabilities.skills` with an email-management SKILL.md describing email operations: inbox triage, folder management, search, compose, reply, and workflow automation.

#### Scenario: Skill delegated to claude-code
- **WHEN** an email client enables `claude-code.skill.enabled = true`
- **THEN** `programs.claude-code.skills` SHALL contain an email-management skill entry with substituted client name

### Requirement: Email client naming accommodates future server role
The service SHALL be named `email` (not `himalaya` or `email-client`) so that a future server role (self-hosted mail) can be added under the same service without renaming.

#### Scenario: Service name is generic
- **WHEN** the email clanService is defined
- **THEN** `manifest.name` SHALL be "email" and the service directory SHALL be `services/email/`
