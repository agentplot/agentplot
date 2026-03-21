## ADDED Requirements

### Requirement: OIDC client configuration namespace
The system SHALL provide a NixOS option namespace `agentplot.oidc.clients.<name>` where each entry is a submodule representing an OIDC client registration for a service.

#### Scenario: Defining a Kanidm OIDC client
- **WHEN** a service configures `agentplot.oidc.clients.linkding` with `provider = "kanidm"`, `issuerUrl`, and `clientId`
- **THEN** the module SHALL auto-derive all four OIDC endpoint URLs using Kanidm's URL structure

#### Scenario: Defining a generic OIDC client
- **WHEN** a service configures `agentplot.oidc.clients.paperless` with `provider = "generic"`
- **THEN** the module SHALL require explicit values for `endpoints.authorization`, `endpoints.token`, `endpoints.userinfo`, and `endpoints.jwks`

### Requirement: Kanidm endpoint auto-derivation
When `provider` is `"kanidm"`, the module SHALL derive endpoint URLs from `issuerUrl` and `clientId` as follows:
- `endpoints.authorization` = `https://{issuerUrl}/ui/oauth2`
- `endpoints.token` = `https://{issuerUrl}/oauth2/token`
- `endpoints.userinfo` = `https://{issuerUrl}/oauth2/openid/{clientId}/userinfo`
- `endpoints.jwks` = `https://{issuerUrl}/oauth2/openid/{clientId}/public_key.jwk`

#### Scenario: Kanidm endpoints are correctly constructed
- **WHEN** `provider = "kanidm"`, `issuerUrl = "auth.example.com"`, and `clientId = "myhost"`
- **THEN** `endpoints.authorization` SHALL equal `"https://auth.example.com/ui/oauth2"`
- **AND** `endpoints.token` SHALL equal `"https://auth.example.com/oauth2/token"`
- **AND** `endpoints.userinfo` SHALL equal `"https://auth.example.com/oauth2/openid/myhost/userinfo"`
- **AND** `endpoints.jwks` SHALL equal `"https://auth.example.com/oauth2/openid/myhost/public_key.jwk"`

### Requirement: Explicit endpoint override
The module SHALL allow explicit endpoint values to override auto-derived values regardless of provider setting.

#### Scenario: Overriding a single Kanidm endpoint
- **WHEN** `provider = "kanidm"` and `endpoints.authorization` is explicitly set to a custom URL
- **THEN** the explicitly set URL SHALL be used for `authorization` while other endpoints remain auto-derived

### Requirement: Client secret via clan.core.vars
Each enabled OIDC client SHALL have a `clan.core.vars` generator named `oidc-{clientName}` that prompts for the client secret and stores it as a secret file. Services access the secret path via the vars generator convention `config.clan.core.vars.generators."oidc-{clientName}".files."client-secret".path`.

#### Scenario: Secret generator is created for enabled client
- **WHEN** `agentplot.oidc.clients.linkding.enable = true`
- **THEN** a vars generator `oidc-linkding` SHALL exist with a prompted secret file at `files."client-secret"`

#### Scenario: Secret file path is accessible via vars convention
- **WHEN** a service needs the client secret file path
- **THEN** it SHALL reference `config.clan.core.vars.generators."oidc-linkding".files."client-secret".path` directly

### Requirement: Provider type validation
The `provider` option SHALL accept only `"kanidm"` or `"generic"` as values.

#### Scenario: Invalid provider is rejected
- **WHEN** `provider` is set to an unrecognized value
- **THEN** NixOS module evaluation SHALL fail with a type error

### Requirement: Client option schema
Each OIDC client submodule SHALL expose the following options: `enable` (bool, default false), `provider` (enum, default "kanidm"), `issuerUrl` (string), `clientId` (string), `endpoints.authorization` (string), `endpoints.token` (string), `endpoints.userinfo` (string), `endpoints.jwks` (string), `signAlgorithm` (string, default "ES256"). The client secret path is accessed via the vars generator convention rather than a submodule option, to avoid circular module evaluation.

#### Scenario: Minimal Kanidm configuration
- **WHEN** a client sets only `enable = true`, `issuerUrl`, and `clientId`
- **THEN** `provider` SHALL default to `"kanidm"`, `signAlgorithm` SHALL default to `"ES256"`, and all endpoints SHALL be auto-derived

### Requirement: Linkding consumes shared OIDC module
The linkding server role SHALL read OIDC endpoint URLs and client secret path from `config.agentplot.oidc.clients.linkding` instead of constructing them inline.

#### Scenario: Linkding OIDC env vars use shared module
- **WHEN** linkding's server role has `oidc.enable = true`
- **THEN** the OIDC environment file SHALL use endpoint URLs from `config.agentplot.oidc.clients.linkding.endpoints.*`
- **AND** the client secret SHALL be read from the shared module's vars generator path

### Requirement: Module exposed in flake outputs
The OIDC module SHALL be exposed in the flake's `nixosModules` and `darwinModules` outputs so services and host configurations can import it.

#### Scenario: Module available as flake output
- **WHEN** a host configuration imports the agentplot flake
- **THEN** `nixosModules.oidc` and `darwinModules.oidc` SHALL be available for import
