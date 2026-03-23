## Why

The __mac-nix repo (precursor to swancloud) and swancloud itself still contain service definitions and agent tooling that belong in agentplot as proper clanServices. Miniflux, Obsidian, Himalaya (email), Tana, and the full OpenClaw and Paperless services (server + client) need agentplot modules so that enabling a service automatically brings its full agent surface — packages, skills, CLI wrappers, restish profiles, and MCP servers. Without this, agent capabilities are fragmented across repos and manually wired.

## What Changes

- **New miniflux clanService** with server role (native NixOS services.miniflux, PostgreSQL, Caddy TLS, borgbackup, kanidm OIDC) and client role (restish CLI, miniflux skill)
- **New obsidian clanService** (client-only) with obsidian-cli, obsidian skill, obsidian-para skill, and syncthing vault sync — vault list configured per agentplot profile
- **New tana clanService** (client-only) with tana-export skill — separate service for Tana knowledge management tooling
- **New himalaya clanService** (client-only) with himalaya CLI and email-management skill — includes email account interface ported from __mac-nix (IMAP/SMTP config, secretspec-based auth, multi-account support)
- **Port openclaw clanService from swancloud** — server role (gateway + channels + agents + providers) and node role, plus client role bundling full CLI ecosystem: lobster (HM global), clawhub, imsg, gogcli, remindctl, blogwatcher, memo, defuddle, and openclaw-workspace skill
- **Port paperless clanService from swancloud** — server role (NixOS services.paperless, PostgreSQL, Caddy TLS, OIDC, borgbackup), plus client role with paperless-cli (restish, fetches OpenAPI from live instance), paperless skill (ported from agentplot-kit), enex2paperless package, and evernote-convert skill
- **Skills routing**: miniflux, obsidian (+para), openclaw-workspace, evernote-convert, tana-export, himalaya, and paperless skills bundled in agentplot with their respective services; sheets-cli stays in agentplot-kit

## Capabilities

### New Capabilities
- `miniflux-server`: Miniflux server role — native NixOS service, PostgreSQL, Caddy TLS, borgbackup, kanidm OIDC
- `miniflux-client`: Miniflux client role — restish CLI profile, miniflux agent skill
- `obsidian-client`: Obsidian client role — obsidian-cli, obsidian skill, obsidian-para skill, syncthing vault sync, per-profile vault mapping
- `himalaya-client`: Himalaya client role — himalaya CLI, email-management skill, multi-account IMAP/SMTP config with secretspec auth
- `tana-client`: Tana client role — tana-export skill for Tana knowledge management export

### Ported Capabilities (from swancloud)
- `openclaw-server`: OpenClaw gateway — agents, channels (telegram/discord/bluebubbles), providers, plugins, caddy TLS
- `openclaw-node`: OpenClaw node — remote gateway connection
- `openclaw-client`: OpenClaw client role — full CLI ecosystem + workspace skill
- `paperless-server`: Paperless-ngx server — NixOS module, PostgreSQL, Caddy TLS, OIDC, borgbackup, tika OCR
- `paperless-client`: Paperless client role — paperless-cli (restish), paperless skill, enex2paperless, evernote-convert skill

### Modified Capabilities
- `client-tooling-framework`: mkClientTooling needs to support client-only services (no server role) and HM-global package installs (lobster)

## Impact

- **services/**: New directories for miniflux, obsidian, himalaya, tana; new openclaw and paperless with full server + client roles
- **flake.nix**: New clan.modules exports (miniflux, obsidian, himalaya, tana, openclaw, paperless), new package outputs (miniflux-cli, paperless-cli)
- **modules/agentplot.nix**: No changes expected — delegation adapter already handles arbitrary service modules
- **tests/**: New composition tests for client-only services and multi-package client roles
- **agentplot-kit**: mkClientTooling enhancement for `extraPackages` support (client-only services and global HM packages) is in scope for this change
- **swancloud**: openclaw and paperless clanServices will be REMOVED from swancloud after this change (swancloud inventory will import from agentplot instead)
