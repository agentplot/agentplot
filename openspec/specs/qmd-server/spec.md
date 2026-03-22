## ADDED Requirements

### Requirement: qmd systemd service
The server role SHALL deploy a systemd service running qmd in Streamable HTTP mode. The service SHALL use `pkgs.llm-agents.qmd` from the llm-agents.nix overlay (not a dedicated flake input) with `--transport http --port <configured-port>` arguments. The service SHALL run as a dedicated system user.

#### Scenario: Service starts with overlay package
- **WHEN** the NixOS system activates with the qmd server role configured
- **THEN** a `qmd` systemd service SHALL start using `pkgs.llm-agents.qmd` from the llm-agents.nix overlay

#### Scenario: Service restarts on failure
- **WHEN** the qmd process exits unexpectedly
- **THEN** systemd SHALL restart the service automatically

### Requirement: Server interface options
The server role interface SHALL expose the following options:
- `domain`: `lib.types.str` — FQDN for the qmd instance (e.g., `qmd.swancloud.net`)
- `port`: `lib.types.port` with default `8423` — HTTP listen port for qmd
- `collections`: `lib.types.attrsOf collectionSubmodule` — named document collections to index

Each collection submodule SHALL have:
- `path`: `lib.types.str` — root directory path containing documents
- `pattern`: `lib.types.str` with default `"**/*.md"` — glob pattern for files to index
- `exclude`: `lib.types.listOf lib.types.str` with default `[]` — glob patterns to exclude

#### Scenario: Minimal server configuration
- **WHEN** a server role is configured with `domain = "qmd.swancloud.net"` and one collection
- **THEN** the service starts with default port 8423 and indexes the specified collection

#### Scenario: Custom port and multiple collections
- **WHEN** a server role is configured with a custom port and multiple collections with different patterns
- **THEN** the service starts on the custom port and indexes all specified collections

### Requirement: Collection configuration generation
The server role SHALL generate qmd's configuration from the declarative `collections` interface options. The generated config SHALL map each named collection to its path, pattern, and exclude settings.

#### Scenario: Config maps collections correctly
- **WHEN** collections are defined with specific paths, patterns, and excludes
- **THEN** qmd receives configuration that indexes exactly those collections with the specified parameters

### Requirement: Caddy reverse proxy
The server role SHALL configure a Caddy virtual host for the configured domain, reverse-proxying to the qmd HTTP port. The Caddy config SHALL use the `caddy-cloudflare` TLS pattern.

#### Scenario: HTTPS access via domain
- **WHEN** a client connects to `https://<domain>`
- **THEN** Caddy terminates TLS and proxies the request to `http://localhost:<port>`

### Requirement: Borgbackup integration
The server role SHALL add qmd's data directory to the borgbackup paths for automated backup.

#### Scenario: Data directory is backed up
- **WHEN** borgbackup runs its scheduled backup
- **THEN** qmd's SQLite databases and cached models are included in the backup

### Requirement: Persistent data directory
The server role SHALL create a persistent data directory for qmd's SQLite databases, model cache, and index data using `systemd.tmpfiles.rules`.

#### Scenario: Data persists across reboots
- **WHEN** the system reboots
- **THEN** qmd's data directory at `/persist/qmd` exists with correct permissions

### Requirement: Firewall configuration
The server role SHALL open TCP port 443 in the NixOS firewall for HTTPS access via Caddy.

#### Scenario: External HTTPS access
- **WHEN** a remote client connects to port 443
- **THEN** the firewall allows the connection through to Caddy

### Requirement: DNS configuration
The server role SHALL configure DNS for the qmd domain pointing to the server.

#### Scenario: Domain resolves to server
- **WHEN** a client resolves `qmd.swancloud.net`
- **THEN** the DNS record points to swancloud-srv's IP address

### Requirement: No dedicated flake input for qmd
The agentplot flake SHALL NOT have a `qmd` flake input. The qmd package SHALL be sourced from the `llm-agents.nix` overlay applied at the consuming machine level.

#### Scenario: qmd flake input removed
- **WHEN** agentplot's `flake.nix` is evaluated
- **THEN** `inputs.qmd` SHALL NOT exist

#### Scenario: Package available via overlay
- **WHEN** the qmd server role references the qmd package
- **THEN** it SHALL use `pkgs.llm-agents.qmd` which is provided by the llm-agents.nix overlay applied by the consuming deployment
