## ADDED Requirements

### Requirement: Miniflux server role provides OCI container with external PostgreSQL
The miniflux server role SHALL deploy a Miniflux OCI container (miniflux/miniflux) configured to use external PostgreSQL at 10.0.0.1:5432 with a generated database password via clan vars.

#### Scenario: Miniflux container starts with PostgreSQL connection
- **WHEN** the miniflux server role is enabled with a configured domain
- **THEN** an OCI container SHALL be created with DATABASE_URL pointing to 10.0.0.1:5432/miniflux, a generated db-password from clan vars, and persistent data at /persist/miniflux

### Requirement: Miniflux server role provides Caddy TLS reverse proxy
The miniflux server role SHALL configure Caddy as a reverse proxy using `config.caddy-cloudflare.tls` for TLS termination, matching the linkding pattern.

#### Scenario: HTTPS access to Miniflux
- **WHEN** the miniflux server role is enabled with `domain = "rss.example.com"`
- **THEN** Caddy SHALL serve a virtualHost for "rss.example.com" with cloudflare TLS config and reverse_proxy to the Miniflux container port

### Requirement: Miniflux server role supports kanidm OIDC authentication
The miniflux server role SHALL support optional OIDC authentication via kanidm, using the shared `agentplot.oidc.clients` interface.

#### Scenario: OIDC enabled with kanidm
- **WHEN** `oidc.enable = true` and `oidc.issuerDomain` is set
- **THEN** the Miniflux container SHALL receive OAUTH2 environment variables derived from the kanidm OIDC client configuration and a prompted client secret from clan vars

#### Scenario: OIDC disabled
- **WHEN** `oidc.enable = false`
- **THEN** no OIDC environment variables SHALL be injected and Miniflux SHALL use its built-in authentication

### Requirement: Miniflux server role configures borgbackup state
The miniflux server role SHALL declare persistent state directories for borgbackup inclusion, matching the pattern used by other services.

#### Scenario: Persistent directories created
- **WHEN** the miniflux server role is enabled
- **THEN** systemd tmpfiles rules SHALL create /persist/miniflux and /persist/caddy directories with appropriate permissions

### Requirement: Miniflux server role restricts firewall to HTTPS
The miniflux server role SHALL only allow TCP port 443 through the firewall.

#### Scenario: Firewall configuration
- **WHEN** the miniflux server role is enabled
- **THEN** `networking.firewall.allowedTCPPorts` SHALL contain only 443

### Requirement: Miniflux server role generates database password
The miniflux server role SHALL create a clan vars generator named "miniflux-db-password" that generates a random hex password using openssl.

#### Scenario: Database password generation
- **WHEN** the miniflux server role is instantiated
- **THEN** a clan vars generator "miniflux-db-password" SHALL exist with `share = true`, a secret file "password" with mode 0440, and a script using `openssl rand -hex 32`
