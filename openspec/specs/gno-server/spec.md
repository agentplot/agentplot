### Requirement: clanService definition with server role
The gno clanService SHALL be defined in `services/gno/default.nix` with `_class = "clan.service"`, `manifest.name = "gno"`, and a `roles.server` entry. The server role description SHALL indicate it deploys the gno document search engine as a native systemd service with Caddy reverse proxy.

#### Scenario: Flake exports gno clanService
- **WHEN** the flake is evaluated
- **THEN** `clan.modules.gno` SHALL be present in the flake outputs as a clanService

### Requirement: Server role interface options
The server role SHALL expose interface options for: `domain` (str, FQDN for the gno instance), `port` (int, default 8422, HTTP listen port), and `collections` (attrsOf submodule with `path` (str, absolute directory path) and `pattern` (str, glob pattern for files to index)).

#### Scenario: Minimal server configuration
- **WHEN** a server instance is configured with `domain = "gno.swancloud.net"` and one collection
- **THEN** the service SHALL deploy with port 8422 and index the specified collection

#### Scenario: Multiple collections configured
- **WHEN** multiple collections are defined in the `collections` attrset
- **THEN** gno SHALL index each collection independently using its path and pattern

### Requirement: Systemd service with bun2nix package
The server role SHALL deploy gno as a systemd service using `pkgs.llm-agents.gno` from the llm-agents.nix overlay. The service SHALL run gno in MCP HTTP mode on the configured port.

#### Scenario: Service starts with native package
- **WHEN** the NixOS system activates with the gno server role configured
- **THEN** a `gno` systemd service SHALL start using the bun2nix-built gno binary from `pkgs.llm-agents.gno`

#### Scenario: Service runs as dedicated user
- **WHEN** the gno service is running
- **THEN** it SHALL run as a dedicated system user with access to `/persist/gno` for data storage

#### Scenario: Service restarts on failure
- **WHEN** the gno process exits unexpectedly
- **THEN** systemd SHALL restart the service automatically

### Requirement: Collection path access
The server role SHALL pass collection paths directly to gno's configuration. Collection directories SHALL be accessible on the guest filesystem (via virtiofs shares for microvm guests or local paths).

#### Scenario: Collections accessible without container mounts
- **WHEN** collections are configured with host paths
- **THEN** gno SHALL access those paths directly on the filesystem without container volume mounts

### Requirement: Caddy reverse proxy
The server role SHALL configure a Caddy virtual host for the configured `domain`, reverse-proxying to `http://localhost:<port>`. TLS SHALL use the `caddy-cloudflare` module's tls config.

#### Scenario: HTTPS access at configured domain
- **WHEN** the server is deployed with `domain = "gno.swancloud.net"`
- **THEN** Caddy SHALL serve HTTPS at `gno.swancloud.net` proxying to the gno container
- **THEN** port 443 SHALL be allowed in the firewall

### Requirement: Borgbackup integration
The server role SHALL include the gno persistent data directory (`/persist/gno`) in borgbackup paths for automated backup.

#### Scenario: Data directory included in backup
- **WHEN** borgbackup runs on the server
- **THEN** `/persist/gno` SHALL be included in the backup set

### Requirement: Native configuration generation
The server role SHALL generate a gno configuration file from the Nix interface options and write it to the filesystem. The config SHALL specify collections, port, and data directory.

#### Scenario: Config file written to filesystem
- **WHEN** collections and port are configured in Nix
- **THEN** a gno config file SHALL be generated and placed at a path accessible to the gno systemd service
