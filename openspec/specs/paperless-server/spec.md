## Purpose

Paperless-ngx server role providing document management with external PostgreSQL, Caddy TLS, optional kanidm OIDC, borgbackup state, and the original paperless CLI and skill, ported from swancloud and agentplot-kit.

## Requirements

### Requirement: Paperless server role ported from swancloud
The paperless clanService SHALL include a `roles.server` (or `roles.default`) definition ported from `swancloud/clanServices/paperless/default.nix`. The server role provides Paperless-ngx via the NixOS module with external PostgreSQL, Caddy TLS, optional kanidm OIDC, and borgbackup state.

#### Scenario: Paperless NixOS module configured with external PostgreSQL
- **WHEN** the paperless server role is enabled
- **THEN** `services.paperless` SHALL be enabled with `PAPERLESS_DBHOST = "10.0.0.1"` and Tika OCR

#### Scenario: Secrets managed via clan vars generators
- **WHEN** the server role is instantiated
- **THEN** clan vars generators SHALL exist for `paperless-db-password`, `paperless-admin-password`, and `paperless-secret-key`, each using openssl random generation

#### Scenario: OIDC authentication via kanidm
- **WHEN** `oidc.enable = true` and `oidc.issuerDomain` is set
- **THEN** `PAPERLESS_APPS` SHALL include the OpenID Connect provider and the OIDC secret SHALL be injected via environment file

#### Scenario: Caddy reverse proxy
- **WHEN** the server role is enabled with a domain
- **THEN** Caddy SHALL reverse proxy to `localhost:28981` with cloudflare TLS

#### Scenario: Borgbackup state
- **WHEN** the server role is enabled
- **THEN** `clan.core.state.paperless.folders` SHALL include `/persist/paperless`

### Requirement: Paperless client uses original CLI from agentplot-kit
The paperless client role SHALL use the paperless-cli that was originally in agentplot-kit (removed in commit 4e178ad). This CLI uses `$PAPERLESS_BASE_URL/api/schema/?format=json` to fetch the OpenAPI spec from the live instance, NOT a bundled static spec.

#### Scenario: CLI fetches live schema
- **WHEN** paperless-cli is invoked
- **THEN** restish SHALL fetch the OpenAPI spec from the running Paperless instance's `/api/schema/` endpoint

### Requirement: Paperless skill ported from agentplot-kit
The paperless client role SHALL include the paperless skill that was originally in `agentplot-kit/skills/paperless/SKILL.md` (removed in commit 4e178ad).

#### Scenario: Skill covers full API surface
- **WHEN** the paperless skill is loaded
- **THEN** it SHALL cover documents, mail rules, tags, correspondents, document types, storage paths, workflows, and system operations
