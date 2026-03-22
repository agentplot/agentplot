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
The server role interface SHALL expose configurable options: `domain` (string, required) and `port` (integer, default 8421).

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
The server role SHALL create a systemd service named `subcog` that runs the subcog binary, passing database connection via environment variables loaded from an environment file. The database URL SHALL connect to PostgreSQL at `10.0.0.1` with a password from the shared `subcog-db-password` vars generator.

#### Scenario: Service starts after network
- **WHEN** the NixOS system boots
- **THEN** the `subcog` systemd service SHALL start after `network.target` and `subcog-env.service`, and be of type `simple`

#### Scenario: Service environment includes database URL with password
- **WHEN** the subcog service starts
- **THEN** it SHALL have `SUBCOG_DATABASE_URL` pointing to `postgresql://subcog:<password>@10.0.0.1/subcog` with the password read from the `subcog-db-password` vars generator

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

### Requirement: Flake output registration
The subcog service SHALL be registered in `flake.nix` as `clan.modules.subcog`.

#### Scenario: Flake exposes subcog module
- **WHEN** `flake.nix` is evaluated
- **THEN** `clan.modules.subcog` SHALL reference `./services/subcog`
