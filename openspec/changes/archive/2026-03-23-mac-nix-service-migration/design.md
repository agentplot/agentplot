## Context

The __mac-nix repo was the original infrastructure-as-code repository before swancloud. Services have been progressively migrated to swancloud and agentplot. AgentPlot already has a mature pattern: linkding, gno, qmd, subcog, and ogham-mcp all follow the `_class = "clan.service"` + `mkClientTooling` pattern.

This change completes the migration by:
- Creating four new services (miniflux, obsidian, himalaya, tana) from __mac-nix definitions
- Porting two full services (openclaw, paperless) from swancloud's `clanServices/` into agentplot with both server and client roles
- All services follow established agentplot conventions

## Goals / Non-Goals

**Goals:**
- Create miniflux clanService with server role (native NixOS module) and client role (restish + skill)
- Create obsidian clanService (client-only) with obsidian-cli, skills, syncthing, and per-profile vault mapping
- Create himalaya clanService (client-only) with himalaya CLI and email-management skill, including multi-account IMAP/SMTP interface ported from __mac-nix
- Create tana clanService (client-only) with tana-export skill
- Port openclaw clanService from swancloud — server role (gateway + channels + agents + providers), node role, and client role with full CLI ecosystem and workspace skill
- Port paperless clanService from swancloud — server role (NixOS module, PostgreSQL, Caddy, OIDC, borgbackup) and client role with paperless-cli (ported from agentplot-kit), paperless skill, enex2paperless, and evernote-convert skill
- Route service-bundled skills into agentplot, generic skills into agentplot-kit

**Non-Goals:**
- Modifying swancloud inventory (consuming side wiring happens in a separate change)
- Removing services from __mac-nix or swancloud (cleanup happens after verification)
- Changing agentplot-kit's mkClientTooling API beyond what's needed for this change (adding `extraPackages` support IS in scope; other API changes are not)

## Decisions

### D1: Miniflux uses native NixOS module, not OCI
Miniflux uses `services.miniflux` from nixpkgs (the package is available), external PostgreSQL at 10.0.0.1:5432, Caddy TLS via `config.caddy-cloudflare.tls`, and kanidm OIDC. The client uses restish with a bundled OpenAPI spec.

**Alternative considered:** OCI container (matching linkding pattern). Rejected because miniflux is packaged in nixpkgs, making native service more reproducible and simpler.

### D2: Client-only services skip the server role entirely
Obsidian, himalaya, and tana have no `roles.server` / `roles.guest`. They define only `roles.client` via `mkClientTooling`. This is valid — mkClientTooling doesn't require a server counterpart.

### D3: Obsidian vault mapping is an agentplot profile concept
Each obsidian client declares its vault list via `extraClientOptions.vaults` (list of strings). Vault-to-profile mapping is part of agentplot's profile system — each agentplot profile declares which vaults it uses. This is NOT delegated to the consumer; agentplot owns the profile-to-vault relationship.

### D4: Obsidian syncthing is an extraClientOption toggle; folder wiring is consumer-level
Syncthing vault sync is declared as `extraClientOptions.syncthing.enable` (bool, default true). Agentplot does NOT generate syncthing folder declarations. The actual syncthing folder wiring belongs in the consuming inventory (swancloud).

### D5: Lobster as a global HM package in openclaw client
Lobster is listed in openclaw's `capabilities.extraPackages`. It installs globally via Home Manager when the openclaw client role is enabled.

### D6: Himalaya includes full account interface from __mac-nix
The himalaya clanService is NOT generic — it ports the email account interface from `__mac-nix/modules/home/loomos/email-accounts.nix`. This includes multi-account IMAP/SMTP configuration with secretspec-based authentication. Account definitions (email, displayName, backend host/port/login, SMTP settings, password keys) are part of the service interface, not deferred to the consumer.

**Alternative considered:** Generic interface with no account config. Rejected — the account definitions are tightly coupled to the himalaya config generation and secretspec wiring. Keeping them generic would just push the complexity to every consumer.

### D7: Service naming
- `services/miniflux/` — RSS reader
- `services/obsidian/` — room for future publish/sync server
- `services/himalaya/` — named after the CLI tool, not "email"
- `services/tana/` — room for future Tana API integration
- `services/openclaw/` — full gateway + node + client
- `services/paperless/` — full server + client

### D8: Skills bundled with their service in agentplot
Skills that are tightly coupled to a service live in `services/<name>/skills/`. Generic skills (sheets-cli) stay in agentplot-kit. The paperless skill and paperless-cli are ported from agentplot-kit (removed in commit 4e178ad) back into `services/paperless/`.

### D9: Obsidian CLI sourced from nixpkgs with app fallback
obsidian-cli should be sourced from nixpkgs if available. If nixpkgs doesn't package it yet, fall back to the app-bundled CLI.

### D10: Lobster workflow registration is consumer-level
Lobster workflow registration happens at the consumer level (swancloud). Agentplot provides lobster as a global tool; workflow YAML files are configured in the consuming inventory.

### D11: codegraph is a general devtool, not openclaw-specific
codegraph is NOT bundled with openclaw. It should be available independently.

### D12: Tana is a standalone client-only service
Tana gets its own service at `services/tana/` rather than being bundled under obsidian.

### D13: Obsidian vault backup is a consumer responsibility
Agentplot exposes vault paths via `extraClientOptions`; the consumer wires them into its backup strategy.

### D14: OpenClaw server role ported verbatim from swancloud
The openclaw server role (gateway + channels + agents + providers + clan vars generators) is ported from `swancloud/clanServices/openclaw/default.nix` with minimal changes. The complex channel/agent/binding configuration is preserved as-is. The node role (remote gateway connection) is also ported.

### D15: Paperless server role ported verbatim from swancloud
The paperless server role is ported from `swancloud/clanServices/paperless/default.nix`. It includes the NixOS services.paperless module, clan vars generators for db-password/admin-password/secret-key, OIDC support, Caddy reverse proxy, and borgbackup state.

### D16: Paperless CLI uses live OpenAPI spec
The paperless-cli (ported from agentplot-kit) fetches the OpenAPI spec from the running Paperless instance (`$PAPERLESS_BASE_URL/api/schema/?format=json`) rather than bundling a static spec file. This means it auto-discovers all endpoints including custom fields and plugins.

## Risks / Trade-offs

**[mkClientTooling needs extraPackages support]** → Adding this support is in scope. The client-tooling-framework spec covers the required API additions. (DONE)

**[Obsidian vault paths are user-specific]** → Mitigation: extraClientOptions.vaultBasePath with a sane default.

**[Large number of openclaw packages]** → 7 packages in one client role plus lobster. All are small CLI tools.

**[OpenClaw server complexity]** → The server role is large (channels, agents, providers, plugins, bindings). Porting verbatim preserves working configuration but makes the service definition complex. This matches the swancloud original.

**[Paperless-cli requires running instance]** → Unlike linkding-cli which bundles its spec, paperless-cli fetches from the live server. If the server is unreachable, restish will fail to load operations.

## Migration Plan

1. Port openclaw server + node roles from swancloud
2. Port paperless server role from swancloud
3. Replace fabricated paperless-cli with original from agentplot-kit
4. Replace fabricated paperless skill with original from agentplot-kit
5. Rename email → himalaya, port account interface from __mac-nix
6. Update flake.nix with all new clan.modules exports
7. Update composition tests
8. Test with `nix flake check` and evaluation tests
9. Update swancloud to import from agentplot instead (separate change)

Rollback: revert commits. No data migration involved — these are module definitions.

## Open Questions

- (None remaining — all resolved, see decisions above)
