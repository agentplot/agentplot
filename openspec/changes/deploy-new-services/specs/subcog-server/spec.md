## REMOVED Requirements

### Requirement: PostgreSQL with pgvector
**Reason**: PostgreSQL runs on the host machine, not inside the service's guest VM. Database provisioning is the responsibility of the inventory consumer (e.g., swancloud-srv), not the clanService.
**Migration**: Remove `services.postgresql` block from server role. Host provisions database via `clan.core.postgresql.databases.subcog` and `clan.core.postgresql.users.subcog`. Service connects to host PG at `10.0.0.1:5432`.

## MODIFIED Requirements

### Requirement: Server interface options
The server role interface SHALL expose configurable options: `domain` (string, required) and `port` (integer, default 8421).

#### Scenario: Domain is required
- **WHEN** a server instance is configured without `domain`
- **THEN** evaluation SHALL fail with a missing option error

#### Scenario: Port defaults to 8421
- **WHEN** a server instance is configured without specifying `port`
- **THEN** the subcog service SHALL listen on port 8421

### Requirement: Systemd service for subcog
The server role SHALL create a systemd service named `subcog` that runs the subcog binary, passing database connection and JWT secret via environment variables. The database URL SHALL connect to PostgreSQL at `10.0.0.1`.

#### Scenario: Service starts after network
- **WHEN** the NixOS system boots
- **THEN** the `subcog` systemd service SHALL start after `network.target` and be of type `simple`

#### Scenario: Service environment includes database URL and JWT secret
- **WHEN** the subcog service starts
- **THEN** it SHALL have `SUBCOG_DATABASE_URL` pointing to `postgresql://subcog@10.0.0.1/subcog` and `SUBCOG_JWT_SECRET` from clan.core.vars

### Requirement: borgbackup for service data
The server role SHALL configure borgbackup to back up the subcog persist directory. PostgreSQL backup is handled on the host, not the guest.

#### Scenario: Backup paths configured
- **WHEN** the server role is applied
- **THEN** borgbackup paths SHALL include `/persist/subcog`
- **THEN** PostgreSQL dump SHALL NOT be performed by the guest (handled on host)
