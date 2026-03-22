## Context

The __mac-nix repo was the original infrastructure-as-code repository before swancloud. Most core services (linkding, paperless, openclaw gateway, skills infra, agent-deck, claude-code, secretspec) have been ported to swancloud/agentplot. Several services and agent tooling bundles remain in __mac-nix that need proper agentplot clanService definitions: Miniflux, Obsidian, email, and expanded package sets for OpenClaw and Paperless.

AgentPlot already has a mature pattern: linkding, gno, qmd, subcog, and ogham-mcp all follow the `_class = "clan.service"` + `mkClientTooling` pattern. This change adds four new services (miniflux, obsidian, email, tana) and updates two existing ones (openclaw, paperless), all following established conventions.

## Goals / Non-Goals

**Goals:**
- Create miniflux clanService with guest (microvm) and client (restish + skill) roles matching the linkding pattern
- Create obsidian clanService (client-only) with obsidian-cli, skills, syncthing, and per-profile vault mapping
- Create email clanService (client-only) with himalaya CLI and email-management skill, keeping it generic
- Create tana clanService (client-only) with tana-export skill
- Expand openclaw client role to bundle its full CLI ecosystem (minus codegraph, which is a general devtool) and workspace skill
- Expand paperless client role to include enex2paperless and generic evernote-convert skill
- Route service-bundled skills into agentplot, generic skills into agentplot-kit

**Non-Goals:**
- Modifying swancloud inventory (consuming side wiring happens in a separate change)
- Removing services from __mac-nix (cleanup happens after verification)
- Building an email server component (future work; module naming accommodates it)
- Changing agentplot-kit's mkClientTooling API beyond what's needed for this change (adding `extraPackages` support IS in scope; other API changes are not)

## Decisions

### D1: Miniflux follows linkding server pattern exactly
Miniflux uses OCI container, external PostgreSQL at 10.0.0.1:5432, Caddy TLS via `config.caddy-cloudflare.tls`, borgbackup state dirs, and kanidm OIDC — identical to linkding. The client uses restish with a bundled OpenAPI spec, same as linkding-cli.

**Alternative considered:** Native systemd service instead of OCI. Rejected because Miniflux upstream provides official Docker images and the OCI pattern is proven with linkding.

### D2: Client-only services skip the server role entirely
Obsidian and email have no `roles.server` / `roles.guest`. They define only `roles.client` via `mkClientTooling`. This is valid — mkClientTooling doesn't require a server counterpart. The `_class = "clan.service"` wrapper still works; it just has one role.

**Alternative considered:** Creating a stub server role. Rejected as unnecessary complexity — the clanService pattern doesn't mandate paired roles.

### D3: Obsidian vault mapping is an agentplot profile concept
Each obsidian client declares its vault list via `extraClientOptions.vaults` (list of strings). Vault-to-profile mapping is part of agentplot's profile system — each agentplot profile declares which vaults it uses. This is NOT delegated to the consumer; agentplot owns the profile-to-vault relationship.

Example agentplot profile config:
```nix
clients.business = { name = "obsidian-biz"; vaults = [ "Business" ]; };
clients.personal = { name = "obsidian"; vaults = [ "Personal" "Creative" ]; };
```

The consumer (swancloud) only needs to enable the profiles it wants; the vault mapping comes from agentplot's profile definitions.

### D4: Obsidian syncthing is an extraClientOption toggle; folder wiring is consumer-level
Syncthing vault sync is declared as `extraClientOptions.syncthing.enable` (bool, default true). Agentplot exposes the `syncthing.enable` flag and vault paths via the interface but does NOT generate syncthing folder declarations in the perInstance HM module. The actual syncthing folder wiring (device IDs, keys, sharing topology, folder declarations) belongs in the consuming inventory (swancloud), which reads the exposed vault paths and enable flag to configure its own syncthing folders.

### D5: Lobster as a global HM package in openclaw client
Lobster is listed in openclaw's `capabilities.cli.extraPackages` (or equivalent). It installs globally via Home Manager, not scoped to a specific openclaw microvm. This means it appears in the user's PATH when the openclaw client role is enabled.

**Alternative considered:** Separate lobster clanService. Rejected — lobster is a workflow tool closely tied to openclaw's ecosystem, not an independent service.

### D6: Email module uses generic interface, no account config
The email clanService defines `extraClientOptions` for account-agnostic settings only (e.g., default folder names, notification behavior). Actual IMAP/SMTP credentials, account names, and server addresses are configured in swancloud via himalaya's HM module directly. This keeps agentplot generic.

### D7: Service naming leaves room for growth
- `services/miniflux/` — room for future reader features
- `services/obsidian/` — room for future publish/sync server
- `services/email/` — room for future self-hosted mail server role
- `services/tana/` — room for future Tana API integration or sync

### D8: Skills bundled with their service in agentplot
Skills that are tightly coupled to a service (miniflux, obsidian, obsidian-para, openclaw-workspace, evernote-convert, email-management, tana-export) live in `services/<name>/skills/`. Generic skills (sheets-cli) stay in agentplot-kit. tana-export lives in `services/tana/skills/` as tana is its own client-only service.

### D9: Obsidian CLI sourced from nixpkgs with app fallback
obsidian-cli should be sourced from nixpkgs if available. If nixpkgs doesn't package it yet, fall back to the app-bundled CLI (the user has a paid early-release version with improvements). This is a resolved decision, not an open question.

### D10: Lobster workflow registration is consumer-level
Lobster workflow registration (e.g., enex-convert.yaml) happens at the consumer level (swancloud). Agentplot provides lobster as a global tool via the openclaw client role; workflow YAML files and their secret injection (e.g., PAPERLESS_API_TOKEN) are configured in the consuming inventory, not in agentplot.

### D11: codegraph is a general devtool, not openclaw-specific
codegraph is a general-purpose development tool and should NOT be bundled exclusively with openclaw. It should be available independently (e.g., in home-packages or as its own lightweight client-only service/module). It is removed from the openclaw extraPackages list.

### D12: Tana is a standalone client-only service
Tana gets its own service at `services/tana/` rather than being bundled under obsidian. Although both are knowledge-management tools, they have independent toolchains and export workflows. The tana service follows the same client-only pattern as obsidian and email, with its client role bundling the tana-export skill.

### D13: Obsidian vault backup is a consumer responsibility
Obsidian vaults should be included in borgbackup. Since obsidian is client-only on Darwin machines, backup of vault paths is a consumer (swancloud) responsibility. Agentplot exposes the vault paths via `extraClientOptions`; the consumer wires them into its backup strategy (e.g., borgbackup include paths). Agentplot does not generate any backup configuration itself.

## Risks / Trade-offs

**[mkClientTooling needs extraPackages support]** → mkClientTooling currently lacks `extraPackages` (packages installed globally, not as CLI wrappers). Adding this support is in scope for this change. The client-tooling-framework spec covers the required API additions.

**[Miniflux OCI image pinning]** → Using `:latest` tag (matching linkding pattern) means no reproducible builds. Mitigation: same pattern as linkding, acceptable for self-hosted services that auto-update.

**[Obsidian vault paths are user-specific]** → Vault paths like `~/Documents/Obsidian/Business` differ per machine. Mitigation: extraClientOptions.vaultBasePath with a sane default, overridable per consumer.

**[Large number of openclaw packages]** → 11 packages in one client role is heavy (codegraph removed — it's a general devtool). Mitigation: all are small CLI tools; the alternative (splitting into sub-services) adds complexity without benefit.

## Migration Plan

1. Create new service directories and definitions (miniflux, obsidian, email, tana)
2. Update existing service definitions (openclaw, paperless)
3. Update flake.nix with new clan.modules exports and package outputs
4. Add composition tests for client-only services and multi-package clients
5. Move skills to their service directories
6. Test with `nix flake check` and evaluation tests
7. Update swancloud inventory to consume new services (separate change)

**Consumer dependency:** The enex-convert.yaml lobster workflow stays in swancloud, not agentplot. Swancloud needs a corresponding change to set up lobster workflow registration and secret injection (PAPERLESS_API_TOKEN) for this pipeline.

Rollback: revert commits. No data migration involved — these are new module definitions.

## Open Questions

- (None remaining — all resolved, see decisions above)
