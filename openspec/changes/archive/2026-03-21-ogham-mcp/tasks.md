## 1. Service Scaffold

- [x] 1.1 Create `services/ogham-mcp/default.nix` with clanService boilerplate (`_class`, manifest, empty roles)
- [x] 1.2 Wire service into `flake.nix` as `clan.modules.ogham-mcp`

## 2. Server Role

- [x] 2.1 Define server role interface options (domain, port, embeddingProvider, ollamaHost, postgresHost)
- [x] 2.2 Implement PostgreSQL provisioning with pgvector extension, database `ogham`, user `ogham`, and vars generator for DB password
- [x] 2.3 Implement systemd service for ogham-mcp via `uvx` with environment variables (DB URL, embedding config, SSE port), dependency on postgresql, and restart-on-failure
- [x] 2.4 Implement Caddy reverse proxy virtual host with caddy-cloudflare TLS
- [x] 2.5 Implement embedding API key vars generator (conditional on provider requiring an API key)
- [x] 2.6 Add firewall rules, borgbackup state registration, and tmpfiles rules
- [x] 2.7 Implement secret injection via systemd preStart (DB password, API key into environment file)

## 3. Client Role

- [x] 3.1 Define client role interface options (clients attrset with name, url, claude-code.mcp.enabled, claude-code.skill.enabled, claude-code.profiles, agent-deck.mcp.enabled)
- [x] 3.2 Implement per-client MCP configuration (SSE URL-based config for claude-code and agent-deck)
- [x] 3.3 Implement HM module delegation (agentplot.hmModules keyed as `ogham-mcp-<clientName>`)
- [x] 3.4 Implement profile-based MCP configuration for claude-code profiles
- [x] 3.5 Implement vars generator for client-side API key with agentplot.user ownership

## 4. Skill Document

- [x] 4.1 Create `services/ogham-mcp/skills/SKILL.md` with YAML frontmatter and agent-facing reference
- [x] 4.2 Wire skill into client role HM module with name substitution

## 5. Verification

- [x] 5.1 Verify `nix flake check` passes (or at minimum `nix eval` on the service module)
- [x] 5.2 Review service against spec requirements for completeness
