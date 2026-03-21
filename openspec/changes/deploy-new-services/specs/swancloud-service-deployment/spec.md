## ADDED Requirements

### Requirement: Microvm guest entries for new services
swancloud's `clan.nix` SHALL define microvm guest entries for `ogham`, `qmd`, `subcog`, and `gno` machines, all with `host = "swancloud-srv"` and tags `["nixos" "microvm"]`.

#### Scenario: Four new guests registered
- **WHEN** the swancloud inventory is evaluated
- **THEN** `inventory.machines` SHALL include `ogham`, `qmd`, `subcog`, and `gno` with `tags = ["nixos" "microvm"]`

#### Scenario: Guests assigned to host
- **WHEN** the microvm instance is evaluated
- **THEN** `roles.guest.machines` SHALL include entries for ogham, qmd, subcog, and gno, each with `settings.host = "swancloud-srv"`

### Requirement: Static IP allocation on microvm bridge
Each new guest SHALL have a static IP on the 10.0.0.0/24 bridge network in its `machines/<name>/configuration.nix`.

#### Scenario: IP addresses assigned
- **WHEN** the guest machine configs are evaluated
- **THEN** ogham SHALL have `10.0.0.7/24`, subcog SHALL have `10.0.0.8/24`, qmd SHALL have `10.0.0.9/24`, and gno SHALL have `10.0.0.12/24`

#### Scenario: Network configuration matches existing pattern
- **WHEN** each guest's `configuration.nix` is evaluated
- **THEN** it SHALL use `systemd.network.networks."20-eth0"` with gateway `10.0.0.1` and DNS `["10.0.0.2" "1.1.1.1"]`

### Requirement: CoreDNS records for new services
swancloud's CoreDNS instance SHALL include DNS entries for each new service, mapping the guest IP to its service names.

#### Scenario: DNS entries for all four services
- **WHEN** the coredns inventory instance is evaluated
- **THEN** `roles.default.machines` SHALL include entries for ogham (10.0.0.7, services: ["ogham-mcp"]), subcog (10.0.0.8, services: ["subcog"]), qmd (10.0.0.9, services: ["qmd"]), and gno (10.0.0.12, services: ["gno"])

### Requirement: PostgreSQL databases on swancloud-srv
swancloud-srv SHALL provision PostgreSQL databases and users for ogham and subcog using `clan.core.postgresql`.

#### Scenario: ogham database provisioned
- **WHEN** swancloud-srv's configuration is evaluated
- **THEN** `clan.core.postgresql.databases.ogham` SHALL exist with `create.options.OWNER = "ogham"` and `restore.stopOnRestore` referencing the ogham microvm

#### Scenario: subcog database provisioned
- **WHEN** swancloud-srv's configuration is evaluated
- **THEN** `clan.core.postgresql.databases.subcog` SHALL exist with `create.options.OWNER = "subcog"` and `restore.stopOnRestore` referencing the subcog microvm

#### Scenario: Database password rotation services
- **WHEN** swancloud-srv boots
- **THEN** oneshot systemd services SHALL set PostgreSQL passwords for ogham and subcog users from shared vars generators

### Requirement: Borgbackup client entries
swancloud's borgbackup instance SHALL include client entries for all four new machines.

#### Scenario: Backup clients registered
- **WHEN** the borgbackup inventory instance is evaluated
- **THEN** `roles.client.machines` SHALL include entries for ogham, qmd, subcog, and gno

### Requirement: Service inventory instances
swancloud's `clan.nix` SHALL define service instances for ogham-mcp, qmd, subcog, and gno with appropriate server role settings including domains.

#### Scenario: ogham-mcp instance configured
- **WHEN** the ogham-mcp inventory instance is evaluated
- **THEN** it SHALL reference `module.input = "agentplot"` and `module.name = "ogham-mcp"` with `roles.server.machines."ogham".settings.domain = "ogham.swancloud.net"`

#### Scenario: subcog instance configured
- **WHEN** the subcog inventory instance is evaluated
- **THEN** it SHALL reference `module.input = "agentplot"` and `module.name = "subcog"` with `roles.server.machines."subcog".settings.domain = "subcog.swancloud.net"`

#### Scenario: qmd instance configured
- **WHEN** the qmd inventory instance is evaluated
- **THEN** it SHALL reference `module.input = "agentplot"` and `module.name = "qmd"` with `roles.server.machines."qmd".settings.domain = "qmd.swancloud.net"`

#### Scenario: gno instance configured
- **WHEN** the gno inventory instance is evaluated
- **THEN** it SHALL reference `module.input = "agentplot"` and `module.name = "gno"` with `roles.server.machines."gno".settings.domain = "gno.swancloud.net"`

### Requirement: Guest machine configurations
Each new guest SHALL have a `machines/<name>/configuration.nix` that imports `caddy-cloudflare.nix` (from agentplot-kit), sets `nixpkgs.hostPlatform`, `networking.hostName`, and configures the static bridge IP.

#### Scenario: Machine config follows existing pattern
- **WHEN** each guest's configuration.nix is evaluated
- **THEN** it SHALL import the caddy-cloudflare module, set the host platform to `x86_64-linux`, and configure `systemd.network.networks."20-eth0"` with the assigned static IP

### Requirement: llm-agents.nix overlay on guest machines
Guest machines running qmd and gno SHALL have access to `pkgs.llm-agents.qmd` and `pkgs.llm-agents.gno` via the llm-agents.nix overlay.

#### Scenario: Overlay applied to guests
- **WHEN** the qmd or gno guest machine's pkgs is evaluated
- **THEN** `pkgs.llm-agents.qmd` and `pkgs.llm-agents.gno` SHALL be available

### Requirement: Client roles on darwin machines
swancloud's darwin machines (mac-studio, macbook-pro) SHALL have client role entries for ogham-mcp, qmd, subcog, and gno using the `mkClientTooling`-generated client interfaces. ogham-mcp clients use `url` (SSE endpoint), while qmd, gno, and subcog clients use `domain` (FQDN).

#### Scenario: MCP endpoints configured on mac-studio
- **WHEN** mac-studio's configuration is evaluated
- **THEN** client roles SHALL configure MCP server entries: ogham-mcp clients with `url = "https://ogham.swancloud.net"`, qmd with `domain = "qmd.swancloud.net"`, subcog with `domain = "subcog.swancloud.net"`, gno with `domain = "gno.swancloud.net"`

### Requirement: caddy-cloudflare import updated
swancloud SHALL import `caddy-cloudflare.nix` from `inputs.agentplot-kit.nixosModules.caddy-cloudflare` instead of the local `./modules/caddy-cloudflare.nix` copy. The local copy SHALL be deleted.

#### Scenario: swancloud-srv uses agentplot-kit module
- **WHEN** swancloud-srv's imports are evaluated
- **THEN** it SHALL import `inputs.agentplot-kit.nixosModules.caddy-cloudflare` (not a local file)

#### Scenario: Guest machines use agentplot-kit module
- **WHEN** guest machine configurations import caddy-cloudflare
- **THEN** they SHALL reference the agentplot-kit module path
