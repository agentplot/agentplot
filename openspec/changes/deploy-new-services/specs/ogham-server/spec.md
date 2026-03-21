## REMOVED Requirements

### Requirement: PostgreSQL database provisioning
**Reason**: PostgreSQL runs on the host machine, not inside the service's guest VM. Database provisioning (user, database, pgvector extension, password rotation) is the responsibility of the inventory consumer (e.g., swancloud-srv's configuration.nix), not the clanService.
**Migration**: Remove `services.postgresql` block from server role. Host provisions database via `clan.core.postgresql.databases.ogham` and `clan.core.postgresql.users.ogham`. Service connects to host PG at `10.0.0.1:5432`.

## MODIFIED Requirements

### Requirement: Server role interface options
The server role SHALL expose interface options for: `domain` (string, FQDN), `port` (integer, default 8420), `embeddingProvider` (enum: openai/ollama/mistral/voyage, default openai), and `ollamaHost` (string, default empty).

#### Scenario: Default option values
- **WHEN** a server role instance is created with only `domain` specified
- **THEN** `port` SHALL be 8420, `embeddingProvider` SHALL be "openai", and `ollamaHost` SHALL be ""

#### Scenario: Custom embedding provider
- **WHEN** `embeddingProvider` is set to "ollama" and `ollamaHost` is set to "http://gpu-host:11434"
- **THEN** the ogham-mcp process SHALL be configured to use the ollama embedding backend at that host

### Requirement: Systemd service for ogham-mcp
The server role SHALL create a systemd service `ogham-mcp` that runs `uvx ogham-mcp` in SSE mode on the configured port. The service SHALL depend on `network.target` and pass database connection and embedding provider configuration via environment variables. The database URL SHALL connect to PostgreSQL at `10.0.0.1` using a password from the shared vars generator.

#### Scenario: Service starts successfully
- **WHEN** the system boots and the network is ready
- **THEN** the `ogham-mcp` systemd service SHALL start and listen for SSE connections on the configured port

#### Scenario: Service environment variables
- **WHEN** the ogham-mcp process starts
- **THEN** it SHALL receive environment variables for: database URL (connecting to `10.0.0.1` with password from `ogham-db-password` vars generator), embedding provider, embedding API key (if applicable), and SSE port

#### Scenario: Service restarts on failure
- **WHEN** the ogham-mcp process exits unexpectedly
- **THEN** systemd SHALL restart it with a 5-second delay

### Requirement: Borgbackup state
The server role SHALL register the ogham-mcp persist directory with `clan.core.state` for borgbackup integration. PostgreSQL backup is handled on the host, not the guest.

#### Scenario: Backup folders registered
- **WHEN** the server role is activated
- **THEN** `clan.core.state.ogham-mcp.folders` SHALL include `/persist/ogham-mcp`
- **THEN** PostgreSQL data SHALL NOT be included (backed up on host)
