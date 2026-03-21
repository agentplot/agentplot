## ADDED Requirements

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
The server role interface SHALL expose configurable options: `domain` (string, required), `port` (integer, default 8421), and `postgresHost` (string, default "localhost").

#### Scenario: Domain is required
- **WHEN** a server instance is configured without `domain`
- **THEN** evaluation SHALL fail with a missing option error

#### Scenario: Port defaults to 8421
- **WHEN** a server instance is configured without specifying `port`
- **THEN** the subcog service SHALL listen on port 8421

#### Scenario: Custom port
- **WHEN** a server instance is configured with `port = 9000`
- **THEN** the subcog service SHALL listen on port 9000

### Requirement: Systemd service for subcog
The server role SHALL create a systemd service named `subcog` that runs the subcog binary, passing database connection and JWT secret via environment variables.

#### Scenario: Service starts after PostgreSQL
- **WHEN** the NixOS system boots
- **THEN** the `subcog` systemd service SHALL start after `postgresql.service` and be of type `simple`

#### Scenario: Service environment includes JWT secret
- **WHEN** the subcog service starts
- **THEN** it SHALL have access to the JWT secret from clan.core.vars via environment or environment file

### Requirement: PostgreSQL with pgvector
The server role SHALL enable PostgreSQL with the pgvector extension and create a database named `subcog`.

#### Scenario: Database and extension provisioned
- **WHEN** the server role is applied
- **THEN** PostgreSQL SHALL be enabled with pgvector in `extraPlugins`, and `ensureDatabases` SHALL include `"subcog"`

#### Scenario: Database user created
- **WHEN** the server role is applied
- **THEN** `ensureUsers` SHALL include a `"subcog"` user with `ensureDBOwnership = true`

### Requirement: JWT secret generation
The server role SHALL generate a JWT secret using `clan.core.vars.generators` with `share = true` so clients can access the same secret.

#### Scenario: Secret is generated and shared
- **WHEN** the server role is applied
- **THEN** a vars generator named `subcog-jwt-secret` SHALL exist with `share = true`, generating a random hex secret

### Requirement: Caddy reverse proxy with TLS
The server role SHALL configure a Caddy virtual host for the configured domain, reverse-proxying to the subcog HTTP port with TLS via the caddy-cloudflare shared module.

#### Scenario: Caddy virtual host configured
- **WHEN** the server role is applied with `domain = "subcog.swancloud.net"`
- **THEN** `services.caddy.virtualHosts."subcog.swancloud.net"` SHALL be configured with `reverse_proxy` to `http://localhost:${port}` and the caddy-cloudflare TLS block

### Requirement: borgbackup for database
The server role SHALL configure borgbackup to back up PostgreSQL dumps of the subcog database.

#### Scenario: Backup job configured
- **WHEN** the server role is applied
- **THEN** a borgbackup job or pre-backup hook SHALL run `pg_dump subcog` and include the dump in the backup

### Requirement: Flake output registration
The subcog service SHALL be registered in `flake.nix` as `clan.modules.subcog`.

#### Scenario: Flake exposes subcog module
- **WHEN** `flake.nix` is evaluated
- **THEN** `clan.modules.subcog` SHALL reference `./services/subcog`
