## 1. Service Scaffold

- [x] 1.1 Create `services/subcog/default.nix` with clanService manifest (`_class`, `manifest.name`, `manifest.description`, `manifest.categories`)
- [x] 1.2 Register `clan.modules.subcog = ./services/subcog` in `flake.nix`

## 2. Server Role

- [x] 2.1 Define server role with interface options: `domain` (string, required), `port` (int, default 8421), `postgresHost` (string, default "localhost")
- [x] 2.2 Add PostgreSQL + pgvector configuration: enable postgresql, add pgvector to extraPlugins, ensureDatabases = ["subcog"], ensureUsers with ensureDBOwnership
- [x] 2.3 Add JWT secret generator via `clan.core.vars.generators."subcog-jwt-secret"` with `share = true`
- [x] 2.4 Add systemd service for subcog binary: after postgresql, environment with database URL and JWT secret, ExecStart pointing to subcog binary
- [x] 2.5 Add Caddy virtual host using caddy-cloudflare TLS, reverse_proxy to localhost:port
- [x] 2.6 Add borgbackup pre-backup hook with `pg_dump subcog`

## 3. Client Role

- [x] 3.1 Define client role with interface options: `domain` (string, required), `claude-code.mcp.enabled` (bool, default false), `agent-deck.mcp.enabled` (bool, default false)
- [x] 3.2 Add JWT token reference from clan.core.vars with owner set to `config.agentplot.user`
- [x] 3.3 Build MCP HTTP endpoint config: url = `https://<domain>/mcp`, JWT bearer token auth
- [x] 3.4 Add HM module delegation: accumulate into `agentplot.hmModules.subcog-<instanceName>` with both nixosModule and darwinModule
- [x] 3.5 Wire claude-code.mcp.enabled to install MCP server config and SKILL.md
- [x] 3.6 Wire agent-deck.mcp.enabled to install agent-deck MCP config

## 4. Agent Skill

- [x] 4.1 Create `services/subcog/skills/SKILL.md` with frontmatter (name, description) and documentation of subcog MCP tool categories (memory, search, entities, namespaces)

## 5. Verification

- [x] 5.1 Run `nix flake check` to verify flake evaluation
- [x] 5.2 Verify the service module evaluates without errors via nix-instantiate
