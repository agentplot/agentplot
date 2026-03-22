## ADDED Requirements

### Requirement: Obsidian service is client-only with no server role
The obsidian clanService SHALL define only `roles.client` with no server or guest role. The service uses `mkClientTooling` for its client role.

#### Scenario: Service definition has only client role
- **WHEN** the obsidian clanService is imported
- **THEN** `roles` SHALL contain only `client` and SHALL NOT contain `server`, `guest`, or `host`

### Requirement: Obsidian client role installs obsidian-cli package
The obsidian client role SHALL declare `capabilities.cli` with the obsidian-cli package, generating per-client CLI wrappers.

#### Scenario: CLI wrapper generated per client
- **WHEN** an obsidian client is configured with `name = "obsidian-biz"`
- **THEN** a CLI wrapper named "obsidian-biz" SHALL be available in the user's PATH

### Requirement: Obsidian client role bundles obsidian and obsidian-para skills
The obsidian client role SHALL declare `capabilities.skills` with two skill files: a general obsidian skill (vault operations, search, note management) and an obsidian-para skill (PARA-based note organization with vault routing).

#### Scenario: Both skills delegated to claude-code
- **WHEN** an obsidian client enables `claude-code.skill.enabled = true`
- **THEN** `programs.claude-code.skills` SHALL contain both an obsidian skill and an obsidian-para skill with substituted client names

#### Scenario: PARA skill routes notes to correct vault
- **WHEN** the obsidian-para skill is active and a client has `vaults = [ "Business" "Personal" ]`
- **THEN** the skill content SHALL describe PARA-based routing rules that map note categories to the configured vault names

### Requirement: Obsidian client exposes per-profile vault list
The obsidian client role SHALL expose `vaults` (list of strings) and `vaultBasePath` (string with default) via `extraClientOptions`, allowing each client to declare which Obsidian vaults it manages.

#### Scenario: Business profile with single vault
- **WHEN** an obsidian client is configured with `vaults = [ "Business" ]` and default vaultBasePath
- **THEN** the client's skill and CLI SHALL reference the "Business" vault at the default base path

#### Scenario: Personal profile with multiple vaults
- **WHEN** an obsidian client is configured with `vaults = [ "Personal" "Creative" ]`
- **THEN** the client's skill and CLI SHALL reference both vaults

### Requirement: Obsidian client supports syncthing vault sync toggle
The obsidian client role SHALL expose `syncthing.enable` (bool, default true) via `extraClientOptions`. When enabled, the perInstance SHALL generate HM module config declaring syncthing folder entries for each vault.

#### Scenario: Syncthing enabled with two vaults
- **WHEN** `syncthing.enable = true` and `vaults = [ "Business" "Personal" ]`
- **THEN** the generated HM module SHALL declare syncthing folder entries for both vault paths

#### Scenario: Syncthing disabled
- **WHEN** `syncthing.enable = false`
- **THEN** no syncthing configuration SHALL be generated
