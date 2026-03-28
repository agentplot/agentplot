### Requirement: clanService manifest
The subcog service SHALL declare `_class = "clan.service"` with `manifest.name = "subcog"` and `manifest.description` describing it as a persistent memory system with hybrid search.

#### Scenario: Service is a valid clanService
- **WHEN** the service module at `services/subcog/default.nix` is evaluated
- **THEN** it SHALL have `_class = "clan.service"` and `manifest.name = "subcog"`

### Requirement: Server role definition
The service SHALL define a `server` role that deploys the subcog binary as a systemd service on NixOS.

#### Scenario: Server role exists with description
- **WHEN** the service is inspected
- **THEN** it SHALL have a `roles.server` with a description indicating it runs the subcog memory server

### Requirement: Server interface options
The server role interface SHALL expose configurable options: `domain` (string, required), `port` (integer, default 8421), `llmProvider` (enum: anthropic/openai/ollama, default "anthropic"), and `llmModel` (string, default "").

#### Scenario: Domain is required
- **WHEN** a server instance is configured without `domain`
- **THEN** evaluation SHALL fail with a missing option error

#### Scenario: Port defaults to 8421
- **WHEN** a server instance is configured without specifying `port`
- **THEN** the subcog service SHALL listen on port 8421

#### Scenario: Custom port
- **WHEN** a server instance is configured with `port = 9000`
- **THEN** the subcog service SHALL listen on port 9000

#### Scenario: LLM provider defaults to anthropic
- **WHEN** a server instance is configured without specifying `llmProvider`
- **THEN** the env file SHALL contain `SUBCOG_LLM_PROVIDER=anthropic`

#### Scenario: LLM model omitted when empty
- **WHEN** a server instance is configured with `llmModel = ""`
- **THEN** the env file SHALL NOT contain `SUBCOG_LLM_MODEL`

#### Scenario: LLM model included when set
- **WHEN** a server instance is configured with `llmModel = "claude-sonnet-4-20250514"`
- **THEN** the env file SHALL contain `SUBCOG_LLM_MODEL=claude-sonnet-4-20250514`

### Requirement: Systemd service for subcog
The server role SHALL create a systemd service named `subcog` that runs the subcog binary, passing database connection via environment variables loaded from an environment file. The storage backend SHALL be configured via `SUBCOG_STORAGE_BACKEND=postgresql` and `SUBCOG_STORAGE_CONNECTION_STRING` pointing to `postgresql://subcog:<password>@10.0.0.1/subcog`.

#### Scenario: Service starts after network
- **WHEN** the NixOS system boots
- **THEN** the `subcog` systemd service SHALL start after `network.target` and `subcog-env.service`, and be of type `simple`

#### Scenario: Service environment includes correct storage vars
- **WHEN** the subcog service starts
- **THEN** the env file SHALL contain `SUBCOG_STORAGE_BACKEND=postgresql` and `SUBCOG_STORAGE_CONNECTION_STRING=postgresql://subcog:<password>@10.0.0.1/subcog` with the password read from the `subcog-db-password` vars generator

### Requirement: Database password generation
The server role SHALL generate a database password using `clan.core.vars.generators` with `share = true` so the host can mirror it for the `ALTER USER` command.

#### Scenario: Password generator exists
- **WHEN** the server role is applied
- **THEN** a vars generator named `subcog-db-password` SHALL exist with `share = true`, producing a random 32-byte hex secret

### Requirement: Caddy reverse proxy with TLS
The server role SHALL configure a Caddy virtual host for the configured domain, reverse-proxying to the subcog HTTP port with TLS via the caddy-cloudflare shared module.

#### Scenario: Caddy virtual host configured
- **WHEN** the server role is applied with `domain = "subcog.swancloud.net"`
- **THEN** `services.caddy.virtualHosts."subcog.swancloud.net"` SHALL be configured with `reverse_proxy` to `http://localhost:${port}` and the caddy-cloudflare TLS block

### Requirement: borgbackup for service data
The server role SHALL configure borgbackup to back up the subcog persist directory. PostgreSQL backup is handled on the host, not the guest.

#### Scenario: Backup paths configured
- **WHEN** the server role is applied
- **THEN** borgbackup paths SHALL include `/persist/subcog`
- **THEN** PostgreSQL dump SHALL NOT be performed by the guest (handled on host)

### Requirement: LLM API key generation
The server role SHALL generate a prompted vars generator `subcog-llm-api-key` when `llmProvider` is `anthropic` or `openai`. The generator SHALL NOT be created when `llmProvider` is `ollama`.

#### Scenario: API key prompted for anthropic
- **WHEN** the server is configured with `llmProvider = "anthropic"`
- **THEN** a vars generator `subcog-llm-api-key` SHALL exist with a hidden prompt for the API key
- **AND** the env file SHALL contain `SUBCOG_LLM_API_KEY` with the prompted value

#### Scenario: No API key for ollama
- **WHEN** the server is configured with `llmProvider = "ollama"`
- **THEN** no vars generator `subcog-llm-api-key` SHALL be created
- **AND** the env file SHALL NOT contain `SUBCOG_LLM_API_KEY`

### Requirement: Persistent JWT secret
The server role SHALL generate the JWT secret via `clan.core.vars.generators."subcog-jwt-secret"` with `share = true`, using `openssl rand -base64 32`. The env file SHALL read the JWT secret from this generator instead of generating it ephemerally at boot.

#### Scenario: JWT secret persists across reboots
- **WHEN** the server is rebooted
- **THEN** the `SUBCOG_MCP_JWT_SECRET` in the env file SHALL be the same value as before the reboot

#### Scenario: JWT secret is shared
- **WHEN** the vars generator `subcog-jwt-secret` is inspected
- **THEN** it SHALL have `share = true`

### Requirement: Pre-signed JWT token for clients
The server role SHALL generate a pre-signed JWT token via `clan.core.vars.generators."subcog-jwt-token"` with `share = true`. The token SHALL be an HS256 JWT with `sub = "agentplot"`, `scopes = ["*"]`, and a long expiry, signed with the shared JWT secret.

#### Scenario: JWT token generator exists
- **WHEN** the server role is applied
- **THEN** a vars generator `subcog-jwt-token` SHALL exist with `share = true`, producing a file named `token`

#### Scenario: JWT token is valid
- **WHEN** the generated token is decoded
- **THEN** it SHALL be a valid HS256 JWT with `sub = "agentplot"` and `scopes = ["*"]`

### Requirement: Flake output registration
The subcog service SHALL be registered in `flake.nix` as `clan.modules.subcog`.

#### Scenario: Flake exposes subcog module
- **WHEN** `flake.nix` is evaluated
- **THEN** `clan.modules.subcog` SHALL reference `./services/subcog`
