## ADDED Requirements

### Requirement: mkClientTooling generates complete client role from capabilities
The `agentplot-kit.lib.mkClientTooling` function SHALL accept a capabilities attrset and return `{ interface; perInstance; }` that can be directly assigned to a clanService's `roles.client`.

#### Scenario: MCP-only service (no skill, no CLI)
- **WHEN** a service calls `mkClientTooling` with `capabilities.mcp` set and `capabilities.skill = null` and `capabilities.cli = null`
- **THEN** the generated interface SHALL contain `claude-code.mcp.enabled`, `claude-code.profiles`, and `agent-deck.mcp.enabled` options but SHALL NOT contain any skill-related options (`claude-code.skill.enabled`, `agent-skills.enabled`, `openclaw.skill.enabled`, `agent-deck.skill.enabled`)

#### Scenario: Skill-only service (no MCP)
- **WHEN** a service calls `mkClientTooling` with `capabilities.skill` set to a path and `capabilities.mcp = null`
- **THEN** the generated interface SHALL contain `claude-code.skill.enabled`, `agent-skills.enabled`, `openclaw.skill.enabled`, and `agent-deck.skill.enabled` options but SHALL NOT contain any MCP-related options

#### Scenario: Full capabilities (skill + MCP + CLI)
- **WHEN** a service calls `mkClientTooling` with all capabilities set
- **THEN** the generated interface SHALL contain all target enable flags

#### Scenario: No capabilities
- **WHEN** a service calls `mkClientTooling` with all capabilities set to null
- **THEN** the generated interface SHALL contain only `extraClientOptions` and the `name` option

### Requirement: Generated interface uses multi-client pattern
The generated `interface` SHALL always use `options.clients = attrsOf clientSubmodule` where each client submodule contains the `name` option, all target enable flags for available capabilities, and any `extraClientOptions`.

#### Scenario: Multiple clients with different targets enabled
- **WHEN** a consumer configures two clients where client A has `claude-code.mcp.enabled = true` and client B has `agent-deck.mcp.enabled = true`
- **THEN** the perInstance SHALL generate separate HM modules for each client with only the enabled targets wired

### Requirement: Generated perInstance wires agentplot.hmModules
The generated `perInstance` SHALL register HM modules into `agentplot.hmModules.${serviceName}-${clientName}` for each configured client, following the established passthrough pattern.

#### Scenario: Two clients generate distinct HM module keys
- **WHEN** serviceName is "qmd" and two clients "docs" and "code" are configured
- **THEN** `agentplot.hmModules` SHALL contain keys `qmd-docs` and `qmd-code`

### Requirement: Target registry is extensible
The target registry within `mkClientTooling` SHALL be structured such that adding a new target requires only adding a new entry to the registry — no changes to the function's public API or to existing services.

#### Scenario: Adding a hypothetical "cursor" target
- **WHEN** a new target `cursor-mcp` is added to the registry requiring the `mcp` capability
- **THEN** all services that declared `capabilities.mcp` SHALL automatically gain a `cursor.mcp.enabled` option without any service code changes

### Requirement: Secret management generates clan vars
When `capabilities.secret` is provided, `mkClientTooling` SHALL generate per-client clan vars generators with naming convention `agentplot-${serviceName}-${clientName}-${secretName}`.

#### Scenario: Prompted secret mode
- **WHEN** `capabilities.secret.mode = "prompted"` and a client "personal" is configured for service "linkding"
- **THEN** a clan vars generator named `agentplot-linkding-personal-api-token` SHALL be created with a `prompts` entry of `type = "hidden"`

#### Scenario: Generated secret mode
- **WHEN** `capabilities.secret.mode = "generated"`
- **THEN** a clan vars generator SHALL be created that auto-generates the secret using openssl

### Requirement: CLI wrapper generation
When `capabilities.cli` is provided, `mkClientTooling` SHALL generate per-client `writeShellApplication` wrappers with the CLI binary name from the client's `name` field, environment variables from `capabilities.cli.envVars`, and the base CLI package from `capabilities.cli.package`.

#### Scenario: Two clients with different CLI names
- **WHEN** two clients are configured with names "linkding" and "linkding-biz"
- **THEN** two distinct wrapper scripts SHALL be generated, each with the correct name and environment variables

### Requirement: Skill content substitution
When `capabilities.skill` is provided, `mkClientTooling` SHALL read the skill template and substitute the service name with the client-specific name in both frontmatter `name:` field and CLI references.

#### Scenario: Client name differs from service name
- **WHEN** serviceName is "linkding" and client name is "linkding-biz"
- **THEN** the generated skill content SHALL have `name: linkding-biz` in frontmatter and all CLI references SHALL use "linkding-biz"

### Requirement: mkClientTooling exposes extraClientOptions
The `extraClientOptions` parameter SHALL allow services to add arbitrary options to the client submodule that are accessible in capability templates via the client settings.

#### Scenario: Service-specific option used in MCP URL
- **WHEN** a service declares `extraClientOptions` with a `domain` option and `capabilities.mcp.urlTemplate = client: "https://${client.domain}/mcp"`
- **THEN** the generated MCP config SHALL use the client's configured domain value
