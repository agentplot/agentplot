## Context

The __mac-nix repo was the original infrastructure-as-code repository before swancloud. Most core services (linkding, paperless, openclaw gateway, skills infra, agent-deck, claude-code, secretspec) have been ported to swancloud/agentplot. Several services and agent tooling bundles remain in __mac-nix that need proper agentplot clanService definitions: Miniflux, Obsidian, email, and expanded package sets for OpenClaw and Paperless.

AgentPlot already has a mature pattern: linkding, gno, qmd, subcog, and ogham-mcp all follow the `_class = "clan.service"` + `mkClientTooling` pattern. This change adds three new services and updates two existing ones, all following established conventions.

## Goals / Non-Goals

**Goals:**
- Create miniflux clanService with guest (microvm) and client (restish + skill) roles matching the linkding pattern
- Create obsidian clanService (client-only) with obsidian-cli, skills, syncthing, and per-profile vault mapping
- Create email clanService (client-only) with himalaya CLI and email-management skill, keeping it generic
- Expand openclaw client role to bundle its full CLI ecosystem and workspace skill
- Expand paperless client role to include enex2paperless and generic evernote-convert skill
- Route service-bundled skills into agentplot, generic skills into agentplot-kit

**Non-Goals:**
- Modifying swancloud inventory (consuming side wiring happens in a separate change)
- Removing services from __mac-nix (cleanup happens after verification)
- Building an email server component (future work; module naming accommodates it)
- Changing agentplot-kit's mkClientTooling API (if client-only and global packages need framework changes, that's a separate agentplot-kit PR)

## Decisions

### D1: Miniflux follows linkding server pattern exactly
Miniflux uses OCI container, external PostgreSQL at 10.0.0.1:5432, Caddy TLS via `config.caddy-cloudflare.tls`, borgbackup state dirs, and kanidm OIDC — identical to linkding. The client uses restish with a bundled OpenAPI spec, same as linkding-cli.

**Alternative considered:** Native systemd service instead of OCI. Rejected because Miniflux upstream provides official Docker images and the OCI pattern is proven with linkding.

### D2: Client-only services skip the server role entirely
Obsidian and email have no `roles.server` / `roles.guest`. They define only `roles.client` via `mkClientTooling`. This is valid — mkClientTooling doesn't require a server counterpart. The `_class = "clan.service"` wrapper still works; it just has one role.

**Alternative considered:** Creating a stub server role. Rejected as unnecessary complexity — the clanService pattern doesn't mandate paired roles.

### D3: Obsidian vault mapping uses extraClientOptions
Each obsidian client declares its vault list via `extraClientOptions.vaults` (list of strings). Profile-to-vault mapping is expressed at the consumer level (swancloud), not in agentplot. Agentplot defines the interface; swancloud populates it.

Example consumer config:
```nix
clients.business = { name = "obsidian-biz"; vaults = [ "Business" ]; };
clients.personal = { name = "obsidian"; vaults = [ "Personal" "Creative" ]; };
```

### D4: Obsidian syncthing is an extraClientOption toggle
Syncthing vault sync is declared as `extraClientOptions.syncthing.enable` (bool, default true). The perInstance generates HM module config for syncthing folder declarations per vault. Actual syncthing device/key config stays in swancloud.

### D5: Lobster as a global HM package in openclaw client
Lobster is listed in openclaw's `capabilities.cli.extraPackages` (or equivalent). It installs globally via Home Manager, not scoped to a specific openclaw microvm. This means it appears in the user's PATH when the openclaw client role is enabled.

**Alternative considered:** Separate lobster clanService. Rejected — lobster is a workflow tool closely tied to openclaw's ecosystem, not an independent service.

### D6: Email module uses generic interface, no account config
The email clanService defines `extraClientOptions` for account-agnostic settings only (e.g., default folder names, notification behavior). Actual IMAP/SMTP credentials, account names, and server addresses are configured in swancloud via himalaya's HM module directly. This keeps agentplot generic.

### D7: Service naming leaves room for growth
- `services/miniflux/` — room for future reader features
- `services/obsidian/` — room for future publish/sync server
- `services/email/` — room for future self-hosted mail server role

### D8: Skills bundled with their service in agentplot
Skills that are tightly coupled to a service (miniflux, obsidian, obsidian-para, openclaw-workspace, evernote-convert, email-management, tana-export) live in `services/<name>/skills/`. Generic skills (sheets-cli) stay in agentplot-kit. tana-export is temporarily housed in the obsidian service since it's note/knowledge-management adjacent.

## Risks / Trade-offs

**[mkClientTooling may need changes for client-only + global packages]** → If mkClientTooling doesn't support `extraPackages` (packages installed globally, not as CLI wrappers), the openclaw expansion may require an agentplot-kit change. Mitigation: check mkClientTooling's current capabilities; if needed, file a separate agentplot-kit change.

**[Miniflux OCI image pinning]** → Using `:latest` tag (matching linkding pattern) means no reproducible builds. Mitigation: same pattern as linkding, acceptable for self-hosted services that auto-update.

**[Obsidian vault paths are user-specific]** → Vault paths like `~/Documents/Obsidian/Business` differ per machine. Mitigation: extraClientOptions.vaultBasePath with a sane default, overridable per consumer.

**[Large number of openclaw packages]** → 12 packages in one client role is heavy. Mitigation: all are small CLI tools; the alternative (splitting into sub-services) adds complexity without benefit.

## Migration Plan

1. Create new service directories and definitions (miniflux, obsidian, email)
2. Update existing service definitions (openclaw, paperless)
3. Update flake.nix with new clan.modules exports and package outputs
4. Add composition tests for client-only services and multi-package clients
5. Move skills to their service directories
6. Test with `nix flake check` and evaluation tests
7. Update swancloud inventory to consume new services (separate change)

Rollback: revert commits. No data migration involved — these are new module definitions.

## Open Questions

- Does mkClientTooling already support `extraPackages` or do we need an agentplot-kit change?
- Should tana-export live in obsidian service or get its own service?
- What's the obsidian-cli package source? (overlay from llm-agents.nix or standalone derivation?)
