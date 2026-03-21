## Why

Agents need persistent, structured memory that survives across sessions and supports intelligent retrieval. ogham-mcp provides hybrid search (semantic + full-text via RRF), a knowledge graph, progressive memory compression, and ACT-R cognitive decay — capabilities that no existing clanService offers. Deploying it as a clanService enables all agent toolchains (Claude Code, agent-deck) to share a single memory backend with partition-scoped isolation.

## What Changes

- Add a new `ogham-mcp` clanService with **server** and **client** roles
- Server role: systemd service running ogham-mcp via `uvx` in SSE mode, PostgreSQL + pgvector database, borgbackup state, Caddy reverse proxy with DNS entry (ogham.swancloud.net)
- Client role: MCP SSE endpoint configuration, HM module delegation for `claude-code.mcp.enabled`, `agent-deck.mcp.enabled`, profile support for partition-scoped memory
- Wire service into `flake.nix` as `clan.modules.ogham-mcp`

## Capabilities

### New Capabilities
- `ogham-server`: Server-side deployment of ogham-mcp — systemd service, PostgreSQL + pgvector provisioning, borgbackup, Caddy virtual host, secret management (API keys, DB credentials), firewall rules
- `ogham-client`: Client-side MCP endpoint configuration — SSE connection to ogham server, HM module delegation for claude-code and agent-deck MCP integration, profile-based partition scoping

### Modified Capabilities
_(none — no existing specs are affected)_

## Impact

- **New files**: `services/ogham-mcp/default.nix`, skill template at `services/ogham-mcp/skills/SKILL.md`
- **Modified files**: `flake.nix` (add `clan.modules.ogham-mcp`)
- **Dependencies**: PostgreSQL + pgvector (NixOS), Python/uvx (runtime), OpenAI API (embedding provider)
- **Systems**: swancloud-srv (server role), darwin machines / VMs (client role)
- **DNS**: New `ogham.swancloud.net` entry via Caddy + Cloudflare
