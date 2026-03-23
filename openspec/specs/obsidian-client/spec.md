## Purpose

Obsidian client-only service providing CLI tooling, dual skills (general and PARA-based organization), per-profile vault configuration, and interface exposure for consumer-level syncthing and backup wiring.

## Requirements

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

### Requirement: Obsidian client exposes per-profile vault list as an agentplot profile concept
The obsidian client role SHALL expose `vaults` (list of strings) and `vaultBasePath` (string with default) via `extraClientOptions`. Vault-to-profile mapping is part of agentplot's profile system — each agentplot profile declares which vaults it uses. The consumer (swancloud) enables profiles but does NOT define vault mappings; those are owned by agentplot.

#### Scenario: Business profile with single vault
- **WHEN** an agentplot profile defines an obsidian client with `vaults = [ "Business" ]` and default vaultBasePath
- **THEN** the client's skill and CLI SHALL reference the "Business" vault at the default base path

#### Scenario: Personal profile with multiple vaults
- **WHEN** an agentplot profile defines an obsidian client with `vaults = [ "Personal" "Creative" ]`
- **THEN** the client's skill and CLI SHALL reference both vaults

### Requirement: Obsidian client exposes syncthing enable flag and vault paths for consumer-level wiring
The obsidian client role SHALL expose `syncthing.enable` (bool, default true) and vault paths via `extraClientOptions` in the interface. Agentplot SHALL NOT generate syncthing folder declarations in the perInstance HM module. The consumer (swancloud) is responsible for reading the exposed vault paths and enable flag to wire its own syncthing folder entries, device IDs, keys, and sharing topology.

#### Scenario: Syncthing enabled with two vaults
- **WHEN** `syncthing.enable = true` and `vaults = [ "Business" "Personal" ]`
- **THEN** the interface SHALL expose both vault paths and the syncthing enable flag for the consumer to wire syncthing folder declarations

#### Scenario: Syncthing disabled
- **WHEN** `syncthing.enable = false`
- **THEN** the interface SHALL expose the disabled flag; the consumer SHALL NOT wire syncthing folders for this client

### Requirement: Obsidian client exposes vault paths for consumer backup integration
The obsidian client role SHALL expose vault paths via `extraClientOptions` so that consumers can include them in their backup strategy (e.g., borgbackup include paths). Agentplot does not generate backup configuration; it only provides the paths.
