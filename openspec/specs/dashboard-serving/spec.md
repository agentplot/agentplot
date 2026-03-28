## Purpose

NixOS/Darwin module for Caddy-based static dashboard serving, providing path-based routing for multiple dashboard sites under a single domain.

## Requirements

### Requirement: Dashboard serving module exists
Agentplot SHALL provide `nixosModules.dashboards` and `darwinModules.dashboards` modules that serve static dashboard HTML files via Caddy with bookmarkable URLs.

#### Scenario: Module available in flake outputs
- **WHEN** a consumer imports `inputs.agentplot.nixosModules.dashboards` (or `darwinModules.dashboards`)
- **THEN** the `agentplot.dashboards` options are available in their NixOS/Darwin config

### Requirement: Dashboard sites configuration
The module SHALL accept an `agentplot.dashboards.sites` attrset where each key is a site name and each value is a Nix derivation containing an `index.html` file.

#### Scenario: Multiple dashboard sites
- **WHEN** consumer configures `agentplot.dashboards.sites = { fleet = fleet-drv; capabilities = cap-drv; }`
- **THEN** both dashboards are served at their respective paths

#### Scenario: Single dashboard site
- **WHEN** consumer configures only one site
- **THEN** that single dashboard is served without errors

### Requirement: Domain configuration
The module SHALL accept an `agentplot.dashboards.domain` option specifying the FQDN for the Caddy virtual host.

#### Scenario: Custom domain
- **WHEN** consumer sets `agentplot.dashboards.domain = "dashboards.swancloud.net"`
- **THEN** Caddy serves the dashboards under that domain

### Requirement: Path-based routing
Each site SHALL be served at `/<site-name>/` under the configured domain. For example, a site named `fleet` is accessible at `https://dashboards.swancloud.net/fleet/`.

#### Scenario: Path routing for two sites
- **WHEN** sites `fleet` and `capabilities` are configured under domain `dashboards.swancloud.net`
- **THEN** `https://dashboards.swancloud.net/fleet/` serves the fleet dashboard and `https://dashboards.swancloud.net/capabilities/` serves the capabilities dashboard

### Requirement: Caddy TLS via agentplot-kit
The module SHALL use `config.caddy-cloudflare.tls` from agentplot-kit for TLS configuration, matching the pattern used by all other agentplot server roles.

#### Scenario: TLS configuration applied
- **WHEN** the dashboards module is enabled alongside caddy-cloudflare
- **THEN** the Caddy virtual host uses the shared TLS block from agentplot-kit

### Requirement: Enable guard
The module SHALL only generate Caddy config when `agentplot.dashboards.enable = true`. When disabled (default), no Caddy routes are added.

#### Scenario: Disabled by default
- **WHEN** the module is imported but `enable` is not set
- **THEN** no Caddy configuration is generated

#### Scenario: Enabled with sites
- **WHEN** `enable = true` and sites are configured
- **THEN** Caddy routes are generated for each site

### Requirement: Static file serving
Each site SHALL be served using Caddy's `file_server` directive pointing at the derivation's output directory. No dynamic processing or proxying is needed.

#### Scenario: Dashboard HTML served correctly
- **WHEN** a browser requests `https://dashboards.swancloud.net/fleet/`
- **THEN** the response is the `index.html` from the fleet dashboard derivation
