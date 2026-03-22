## Why

The __mac-nix repo (precursor to swancloud) still contains service definitions and agent tooling that belong in agentplot as proper clanServices. Miniflux, Obsidian, email, and expanded OpenClaw/Paperless tooling need agentplot modules so that enabling a service automatically brings its full agent surface — packages, skills, CLI wrappers, restish profiles, and MCP servers. Without this, agent capabilities are fragmented across repos and manually wired.

## What Changes

- **New miniflux clanService** with guest role (microvm, PostgreSQL, Caddy TLS, borgbackup, kanidm OIDC) and client role (restish CLI, miniflux skill) — mirrors linkding pattern
- **New obsidian clanService** (client-only) with obsidian-cli, obsidian skill, obsidian-para skill, and syncthing vault sync — vault list configured per agentplot profile
- **New email clanService** (client-only for now) with himalaya CLI and email-management skill — generic module, account config stays in swancloud
- **Expanded openclaw client role** to bundle full CLI ecosystem: lobster (HM global), clawhub, ppls, imsg, gogcli, remindctl, blogwatcher, memo, defuddle, codegraph, and openclaw-workspace skill
- **Expanded paperless client role** to include enex2paperless package and generic evernote-convert skill
- **Skills routing**: miniflux, obsidian (+para), openclaw-workspace, evernote-convert, tana-export, and email skills bundled in agentplot; sheets-cli stays in agentplot-kit

## Capabilities

### New Capabilities
- `miniflux-server`: Miniflux guest role — microvm, PostgreSQL, Caddy TLS, borgbackup, kanidm OIDC
- `miniflux-client`: Miniflux client role — restish CLI profile, miniflux agent skill
- `obsidian-client`: Obsidian client role — obsidian-cli, obsidian skill, obsidian-para skill, syncthing vault sync, per-profile vault mapping
- `email-client`: Email client role — himalaya CLI, email-management skill, generic account interface

### Modified Capabilities
- `openclaw-skill-delegation`: OpenClaw client now bundles full CLI ecosystem (lobster, clawhub, ppls, imsg, gogcli, remindctl, blogwatcher, memo, defuddle, codegraph) and openclaw-workspace skill
- `client-tooling-framework`: mkClientTooling needs to support client-only services (no server role) and HM-global package installs (lobster)

## Impact

- **services/**: New directories for miniflux, obsidian, email; updates to openclaw and paperless
- **flake.nix**: New clan.modules exports (miniflux, obsidian, email), new package outputs, updated openclaw/paperless definitions
- **modules/agentplot.nix**: No changes expected — delegation adapter already handles arbitrary service modules
- **tests/**: New composition tests for client-only services and multi-package client roles
- **agentplot-kit**: May need mkClientTooling enhancement for client-only services and global HM packages (separate PR)
- **swancloud**: Consuming inventory will need to wire new services (out of scope for this change)
