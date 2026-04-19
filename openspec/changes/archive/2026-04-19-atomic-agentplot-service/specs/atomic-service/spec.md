## ADDED Requirements

### Requirement: OCI container deployment
The Atomic service module SHALL deploy the Atomic server as an OCI container using the all-in-one `ghcr.io/kenforthewin/atomic` image (bundled server + web UI). The container MUST mount `/persist/atomic` as `/data` inside the container (the image's default data directory) and MUST publish the container's internal HTTP listener on the host via the configurable `port` option.

#### Scenario: Container starts successfully
- **WHEN** the microvm guest boots
- **THEN** the Atomic OCI container starts and the `/health` endpoint returns HTTP 200 on the host port

#### Scenario: Data directory is persisted
- **WHEN** the container writes to `/data` (backed by the `/persist/atomic` host bind mount)
- **THEN** data survives container and microvm restarts via the virtiofs mount

### Requirement: Caddy TLS reverse proxy
The module SHALL configure Caddy as a reverse proxy in front of the Atomic server, terminating TLS via ACME DNS-01 with the Cloudflare plugin. The Caddy data directory MUST be on the persisted volume at `/persist/caddy`.

#### Scenario: HTTPS access
- **WHEN** a client requests `https://<configured-domain>/`
- **THEN** Caddy terminates TLS and proxies to `http://localhost:8080`

#### Scenario: Certificate persistence
- **WHEN** the microvm restarts
- **THEN** Caddy reuses cached ACME certificates from `/persist/caddy` without re-requesting

### Requirement: Bearer token provisioning
The module SHALL generate an admin bearer token via a clan vars generator. A oneshot systemd service MUST create the token in Atomic's database by invoking `atomic-server token create` inside the container (via `podman exec`) after the server is healthy.

#### Scenario: First boot token creation
- **WHEN** the Atomic server starts for the first time
- **THEN** a oneshot service polls the `/health` endpoint until healthy, then runs `podman exec atomic atomic-server token create --name admin --data-dir /data`

#### Scenario: Subsequent boots skip token creation
- **WHEN** the Atomic server starts and an `admin`-named token already exists in the database
- **THEN** the provisioning service detects it via `token list` and completes without re-creating (idempotent)

### Requirement: Borgbackup state declaration
The module SHALL declare `/persist/atomic` as a backup-eligible folder via `clan.core.state.atomic.folders`.

#### Scenario: Backup includes Atomic data
- **WHEN** borgbackup runs on swancloud-srv
- **THEN** the `/persist/atomic` directory (containing SQLite database and all state) is included in the backup

### Requirement: Firewall configuration
The module SHALL open TCP port 443 on the microvm guest firewall for HTTPS access.

#### Scenario: External HTTPS access
- **WHEN** a client on the bridge network or Tailscale connects to the guest on port 443
- **THEN** the connection is accepted and routed through Caddy

### Requirement: Interface options
The module SHALL expose a `domain` option (FQDN string) in its interface. The module MAY expose an optional `port` option (default 8080) for the internal Atomic server port.

#### Scenario: Domain configuration
- **WHEN** an instance sets `domain = "atomic.swancloud.net"`
- **THEN** Caddy configures its virtual host for that domain and the Atomic server receives `PUBLIC_URL=https://atomic.swancloud.net`

### Requirement: Agentplot service structure
The module SHALL follow the `_class = "clan.service"` pattern with `manifest`, `roles.server`, `interface`, and `perInstance` structure. No fleet-specific configuration (IPs, domains, machine names) SHALL be hardcoded in the service module.

#### Scenario: Module is portable
- **WHEN** the service module is imported into a different Clan fleet
- **THEN** it functions correctly with only instance-level settings (domain, port) provided

#### Scenario: Flake export
- **WHEN** the agentplot flake is built
- **THEN** `clan.modules.atomic` is available as an output

### Requirement: Client role agent tooling
The module SHALL provide a `client` role built on `mkClientTooling` that wires an Atomic MCP endpoint into Claude Code on client machines (NixOS or Darwin). The client role MUST use a `prompted` secret mode for the admin bearer token (user supplies per-client) and MUST expose a per-client `claude-code.mcp.enabled` toggle and a `domain` option identifying the server instance.

#### Scenario: MCP wired into Claude Code
- **WHEN** a client instance sets `claude-code.mcp.enabled = true` and `domain = "atomic.swancloud.net"`
- **THEN** Home Manager configures `programs.claude-code.mcpServers.atomic` to run a wrapper that shells out to `npx -y mcp-remote https://<domain>/mcp` with an `Authorization: Bearer <token>` header, where `<token>` is read at runtime from the prompted secret file

#### Scenario: MCP disabled by default
- **WHEN** a client instance does not set `claude-code.mcp.enabled`
- **THEN** no MCP server entry is added to Claude Code (opt-in)
