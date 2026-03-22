## ADDED Requirements

### Requirement: Himalaya service is client-only with multi-account interface
The himalaya clanService SHALL define only `roles.client` with no server role. The service SHALL be named `himalaya`. The client role SHALL include the email account interface ported from `__mac-nix/modules/home/loomos/email-accounts.nix`, supporting multi-account IMAP/SMTP configuration.

#### Scenario: Service definition has only client role
- **WHEN** the himalaya clanService is imported
- **THEN** `roles` SHALL contain only `client` and SHALL NOT contain `server`

#### Scenario: Service named himalaya
- **WHEN** the himalaya clanService is defined
- **THEN** `manifest.name` SHALL be "himalaya" and the service directory SHALL be `services/himalaya/`

### Requirement: Himalaya client installs himalaya package
The himalaya client role SHALL declare `capabilities.cli` with the himalaya email client package from nixpkgs, generating per-client CLI wrappers.

#### Scenario: CLI wrapper generated per client
- **WHEN** a himalaya client is configured with `name = "himalaya"`
- **THEN** a CLI wrapper named "himalaya" SHALL be available in the user's PATH

### Requirement: Himalaya client bundles email-management skill
The himalaya client role SHALL declare `capabilities.skills` with an email-management SKILL.md describing email operations: inbox triage, folder management, search, compose, reply, and workflow automation via himalaya CLI.

### Requirement: Himalaya client exposes multi-account email configuration
The himalaya client role SHALL expose `extraClientOptions` with an `accounts` attrset matching the interface from `__mac-nix/modules/home/loomos/email-accounts.nix`. Each account includes:
- `email` (string) — email address
- `displayName` (string) — display name for outgoing mail
- `default` (bool) — whether this is the default account
- `backend.type` (string, default "imap") — backend type
- `backend.host` (string) — IMAP server hostname
- `backend.port` (port) — IMAP server port
- `backend.login` (string) — IMAP login username
- `backend.passwordKey` (string) — secretspec key name for IMAP password
- `smtp.host` (string) — SMTP server hostname
- `smtp.port` (port) — SMTP server port
- `smtp.login` (string) — SMTP login username
- `smtp.encryption` (enum: tls, start-tls, none, or null) — SMTP encryption type
- `smtp.passwordKey` (string) — secretspec key name for SMTP password

#### Scenario: Multiple accounts configured
- **WHEN** a himalaya client defines accounts for icloud and zoho
- **THEN** the generated himalaya config.toml SHALL contain `[accounts.icloud]` and `[accounts.zoho]` sections with correct IMAP/SMTP settings

#### Scenario: SecretSpec integration for passwords
- **WHEN** accounts reference passwordKey values
- **THEN** the HM module SHALL generate secretspec declarations and a `himalaya-get-secret` wrapper that retrieves passwords at runtime

### Requirement: Himalaya config generation matches __mac-nix pattern
The perInstance HM module SHALL generate `~/.config/himalaya/config.toml` with TOML account blocks matching the pattern from `__mac-nix/modules/home/loomos/himalaya.nix`. Authentication SHALL use `backend.auth.cmd` pointing to a secretspec get wrapper.
