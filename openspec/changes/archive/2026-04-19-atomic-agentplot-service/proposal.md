## Why

The knowledge management stack currently has GNO for document RAG and Ogham for agent memory, but lacks a unified tool for semantic note-taking with built-in wiki synthesis and RAG chat. Atomic (kenforthewin/atomic) fills this gap — a self-hosted, SQLite-backed knowledge base with native vector search, auto-tagging, and LLM-powered wiki generation. Adding it as an agentplot clanService makes it deployable by any Clan fleet.

## What Changes

- New `services/atomic/default.nix` agentplot clanService with server + client roles
- OCI container deployment (`ghcr.io/kenforthewin/atomic:latest`, all-in-one server + web UI)
- Caddy reverse proxy with ACME DNS-01 TLS at a configurable FQDN
- Clan vars generator for admin bearer token
- Persistent state declaration for borgbackup (`/persist/atomic`)
- MCP server exposed on a configurable port for Tailscale access
- Client role (via `mkClientTooling`) wires Atomic MCP into Claude Code with a prompted bearer token
- No OIDC integration — Atomic uses bearer token auth managed via CLI/API
- LLM provider configuration done through the web UI post-deploy (not server-level config)
- Export as `clan.modules.atomic` in agentplot `flake.nix`

## Capabilities

### New Capabilities
- `atomic-service`: Agentplot clanService for deploying Atomic with OCI container, Caddy TLS, bearer token auth, MCP exposure, and borgbackup state

### Modified Capabilities

_(none — no existing specs are affected)_

## Impact

- **New files**: `services/atomic/default.nix`
- **Modified files**: `flake.nix` (export `clan.modules.atomic`)
- **Downstream (swancloud)**: Machine entry, inventory wiring, DNS record, coredns entry
- **Dependencies**: Upstream OCI image `ghcr.io/kenforthewin/atomic-server`
