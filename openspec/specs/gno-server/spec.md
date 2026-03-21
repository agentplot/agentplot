### Requirement: clanService definition with server role
The gno clanService SHALL be defined in `services/gno/default.nix` with `_class = "clan.service"`, `manifest.name = "gno"`, and a `roles.server` entry. The server role description SHALL indicate it deploys the gno document search engine as an OCI container with Caddy reverse proxy.

#### Scenario: Flake exports gno clanService
- **WHEN** the flake is evaluated
- **THEN** `clan.modules.gno` SHALL be present in the flake outputs as a clanService

### Requirement: Server role interface options
The server role SHALL expose interface options for: `domain` (str, FQDN for the gno instance), `port` (int, default 8422, container listen port), and `collections` (attrsOf submodule with `path` (str, absolute directory path) and `pattern` (str, glob pattern for files to index)).

#### Scenario: Minimal server configuration
- **WHEN** a server instance is configured with `domain = "gno.swancloud.net"` and one collection
- **THEN** the service SHALL deploy with port 8422 and index the specified collection

#### Scenario: Multiple collections configured
- **WHEN** multiple collections are defined in the `collections` attrset
- **THEN** gno SHALL index each collection independently using its path and pattern

### Requirement: OCI container deployment
The server role SHALL deploy gno as a Podman OCI container via `virtualisation.oci-containers`. The container SHALL bind-mount `/persist/gno` for persistent sqlite database and model cache storage. The container SHALL expose the configured port.

#### Scenario: Container runs with persistent storage
- **WHEN** the server role is activated
- **THEN** a podman container named `gno` SHALL run with `/persist/gno` bind-mounted to the gno data directory
- **THEN** the container SHALL listen on the configured port

#### Scenario: Persistent directories created
- **WHEN** the server role is activated
- **THEN** `systemd.tmpfiles.rules` SHALL ensure `/persist/gno` exists with appropriate permissions

### Requirement: Collection bind-mounts
The server role SHALL generate bind-mount entries for each configured collection, mapping the host `path` into the container at a deterministic mount point.

#### Scenario: Collection directories available in container
- **WHEN** a collection with `path = "/data/notes"` is configured
- **THEN** the container SHALL have a bind-mount making that directory accessible inside the container

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

### Requirement: Gno configuration generation
The server role SHALL generate a gno configuration file from the Nix interface options, specifying the collections to index, listen port, and storage paths. This config SHALL be written to a path accessible by the container.

#### Scenario: Config file reflects Nix options
- **WHEN** collections and port are configured in Nix
- **THEN** a gno config file SHALL be generated with matching collection definitions and port setting
- **THEN** the container SHALL mount this config file
