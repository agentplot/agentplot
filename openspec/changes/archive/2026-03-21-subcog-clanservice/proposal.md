## Why

Agents need persistent, structured memory that survives across sessions — entity-centric knowledge graphs, hybrid search (vector + keyword + graph), and namespace-scoped retention policies. Subcog is a Rust-based memory system providing exactly this via ~40+ MCP tools, backed by PostgreSQL + pgvector. Adding it as a clanService enables declarative deployment of the server (with database, auth, backups, DNS) and automatic client wiring (MCP endpoints, skills, HM delegation) across all agent-enabled machines.

## What Changes

- Add `services/subcog/default.nix` — new clanService with server and client roles
- **Server role** (`swancloud-srv`): systemd service for subcog binary, PostgreSQL + pgvector database, JWT auth secret management, borgbackup integration, Caddy reverse proxy with TLS (subcog.swancloud.net)
- **Client role** (darwin/VMs): MCP HTTP endpoint configuration, JWT token secret, HM module delegation for `claude-code.mcp.enabled` and `agent-deck.mcp.enabled`
- Add `services/subcog/skills/SKILL.md` — agent skill for subcog MCP tools
- Register `clan.modules.subcog` in `flake.nix`

## Capabilities

### New Capabilities
- `subcog-server`: Server-side deployment — systemd service, PostgreSQL + pgvector provisioning, JWT auth, borgbackup, Caddy reverse proxy with DNS-01 TLS
- `subcog-client`: Client-side wiring — MCP HTTP endpoint config, JWT token management, SKILL.md, HM module delegation for claude-code and agent-deck

### Modified Capabilities

(none)

## Impact

- `services/subcog/` — new service directory with default.nix, skills/SKILL.md
- `flake.nix` — add `clan.modules.subcog` output
- Depends on shared `modules/caddy-cloudflare.nix` for TLS
- Depends on `clan.core.vars.generators` for JWT secret management
- Runtime dependency: subcog binary (Rust, fetched/built via Nix), PostgreSQL with pgvector extension
- Network: port 8421 (subcog HTTP), DNS record for configured domain
