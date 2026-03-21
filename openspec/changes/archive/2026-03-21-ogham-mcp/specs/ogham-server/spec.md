## ADDED Requirements

### Requirement: clanService manifest
The ogham-mcp service SHALL be a valid clanService with `_class = "clan.service"`, manifest name `ogham-mcp`, and category `Application`.

#### Scenario: Service definition is valid
- **WHEN** the service is loaded by the Clan framework
- **THEN** it SHALL have `_class = "clan.service"`, `manifest.name = "ogham-mcp"`, and `manifest.categories = ["Application"]`

### Requirement: Server role interface options
The server role SHALL expose interface options for: `domain` (string, FQDN), `port` (integer, default 8420), `embeddingProvider` (enum: openai/ollama/mistral/voyage, default openai), `ollamaHost` (string, default empty), and `postgresHost` (string, default "localhost").

#### Scenario: Default option values
- **WHEN** a server role instance is created with only `domain` specified
- **THEN** `port` SHALL be 8420, `embeddingProvider` SHALL be "openai", `ollamaHost` SHALL be "", and `postgresHost` SHALL be "localhost"

#### Scenario: Custom embedding provider
- **WHEN** `embeddingProvider` is set to "ollama" and `ollamaHost` is set to "http://gpu-host:11434"
- **THEN** the ogham-mcp process SHALL be configured to use the ollama embedding backend at that host

### Requirement: PostgreSQL database provisioning
The server role SHALL enable `services.postgresql` with the pgvector extension and create a database named `ogham` with user `ogham`. The database password SHALL be managed via `clan.core.vars.generators`.

#### Scenario: PostgreSQL is provisioned
- **WHEN** the server role NixOS module is activated
- **THEN** PostgreSQL SHALL be running with pgvector extension loaded, database `ogham` SHALL exist, and user `ogham` SHALL have access

#### Scenario: Database password is generated
- **WHEN** the vars generator `ogham-db-password` runs
- **THEN** it SHALL produce a random 32-byte hex secret stored at `files.password.path` with `secret = true`

### Requirement: Systemd service for ogham-mcp
The server role SHALL create a systemd service `ogham-mcp` that runs `uvx ogham-mcp` in SSE mode on the configured port. The service SHALL depend on `postgresql.service` and pass database connection and embedding provider configuration via environment variables.

#### Scenario: Service starts successfully
- **WHEN** the system boots and PostgreSQL is ready
- **THEN** the `ogham-mcp` systemd service SHALL start and listen for SSE connections on the configured port

#### Scenario: Service environment variables
- **WHEN** the ogham-mcp process starts
- **THEN** it SHALL receive environment variables for: database URL (constructed from postgresHost, password, database name), embedding provider, embedding API key (if applicable), and SSE port

#### Scenario: Service restarts on failure
- **WHEN** the ogham-mcp process exits unexpectedly
- **THEN** systemd SHALL restart it with a 5-second delay

### Requirement: Caddy reverse proxy
The server role SHALL configure a Caddy virtual host for the configured domain that reverse-proxies to the ogham-mcp SSE port. TLS SHALL use the caddy-cloudflare module configuration.

#### Scenario: HTTPS access
- **WHEN** a client connects to `https://<domain>`
- **THEN** Caddy SHALL proxy the request to `http://localhost:<port>` and terminate TLS

### Requirement: Firewall rules
The server role SHALL open TCP port 443 in the NixOS firewall for HTTPS access.

#### Scenario: Port 443 is open
- **WHEN** the server role module is activated
- **THEN** `networking.firewall.allowedTCPPorts` SHALL include 443

### Requirement: Secret management for embedding API key
The server role SHALL manage the embedding provider API key via `clan.core.vars.generators` with a prompted secret. This is required when `embeddingProvider` is "openai", "mistral", or "voyage".

#### Scenario: OpenAI API key prompt
- **WHEN** `embeddingProvider` is "openai" and the vars generator runs
- **THEN** it SHALL prompt for the API key with type "hidden" and store it as a secret file

#### Scenario: Ollama requires no API key
- **WHEN** `embeddingProvider` is "ollama"
- **THEN** no embedding API key vars generator SHALL be created

### Requirement: Borgbackup state
The server role SHALL register PostgreSQL data and persist directories with `clan.core.state` for borgbackup integration.

#### Scenario: Backup folders registered
- **WHEN** the server role is activated
- **THEN** `clan.core.state.ogham-mcp.folders` SHALL include the PostgreSQL data directory path

### Requirement: Persistent data directories
The server role SHALL create tmpfiles rules for persistent data directories used by the service.

#### Scenario: Tmpfiles rules exist
- **WHEN** the module is activated
- **THEN** `systemd.tmpfiles.rules` SHALL create `/persist/ogham-mcp` with appropriate ownership
