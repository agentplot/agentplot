## Purpose

Caddy reverse proxy module with Cloudflare DNS-01 ACME TLS, exported from agentplot-kit for use by clanServices that need HTTPS termination.

## Requirements

### Requirement: agentplot-kit exports caddy-cloudflare NixOS module
agentplot-kit SHALL export `nixosModules.caddy-cloudflare` in its `flake.nix` outputs, pointing to `modules/caddy-cloudflare.nix`.

#### Scenario: Module available in flake outputs
- **WHEN** agentplot-kit's flake is evaluated
- **THEN** `nixosModules.caddy-cloudflare` SHALL be present in the outputs

### Requirement: Cloudflare DNS-01 ACME TLS configuration
The module SHALL provide a `caddy-cloudflare.tls` option (string) containing the Caddy TLS block for DNS-01 ACME via Cloudflare. This option SHALL be set automatically when `services.caddy.enable` is true.

#### Scenario: TLS config available when Caddy is enabled
- **WHEN** `services.caddy.enable = true` on a NixOS machine that imports the module
- **THEN** `config.caddy-cloudflare.tls` SHALL contain a Caddy TLS block referencing `{env.CLOUDFLARE_API_TOKEN}` with Cloudflare DNS resolver

#### Scenario: TLS config empty when Caddy is disabled
- **WHEN** `services.caddy.enable = false`
- **THEN** `config.caddy-cloudflare.tls` SHALL be the empty string

### Requirement: Custom Caddy build with Cloudflare plugin
The module SHALL override `services.caddy.package` with a Caddy build that includes the `caddy-dns/cloudflare` plugin.

#### Scenario: Caddy package includes Cloudflare DNS plugin
- **WHEN** the module is active and Caddy is enabled
- **THEN** `services.caddy.package` SHALL be built with `pkgs.caddy.withPlugins` including the cloudflare DNS plugin

### Requirement: Cloudflare API token from clan vars
The module SHALL create a `clan.core.vars.generators.cloudflare-dns-token` that prompts for the Cloudflare API token (Zone.Zone:Read + Zone.DNS:Edit permissions). The prompt description SHALL NOT reference any specific domain.

#### Scenario: Token generator created
- **WHEN** Caddy is enabled
- **THEN** a vars generator named `cloudflare-dns-token` SHALL exist with `share = true` and a hidden prompt for the API token

#### Scenario: Prompt is domain-agnostic
- **WHEN** the vars generator prompt is displayed
- **THEN** the description SHALL describe the required Cloudflare permissions without referencing a specific domain name

### Requirement: Environment file for Caddy
The module SHALL create a oneshot systemd service `caddy-env` that writes the Cloudflare API token to `/run/caddy-cloudflare.env` before Caddy starts. Caddy's service SHALL load this environment file.

#### Scenario: Token available to Caddy at startup
- **WHEN** the Caddy service starts
- **THEN** `caddy-env.service` SHALL have already written `/run/caddy-cloudflare.env` containing `CLOUDFLARE_API_TOKEN=<token>`
- **THEN** `systemd.services.caddy.serviceConfig.EnvironmentFile` SHALL point to `/run/caddy-cloudflare.env`
