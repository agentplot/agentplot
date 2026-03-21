# subcog

Persistent agent memory with hybrid search (vector + keyword + graph), entity-centric knowledge graph, and namespace-scoped retention policies. Built in Rust.

## Roles

### Server

Deploys the subcog binary as a systemd service with PostgreSQL/pgvector backend and Caddy reverse proxy. JWT-based authentication with auto-generated secrets.

### Client

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| Skill | MCP-oriented skill describing memory and knowledge graph tools |
| MCP | HTTP Streamable endpoint for MCP tool access |
| Secret | Auto-generated JWT secret per client |

**Available targets:** `claude-code.skill`, `claude-code.mcp`, `claude-code.profiles`, `agent-skills`, `agent-deck.mcp`, `agent-deck.skill`, `openclaw.skill`

## Example Inventory

```nix
{
  services.subcog.server.swan = {
    roles = [ "server" ];
    config = {
      domain = "subcog.swancloud.net";
    };
  };

  services.subcog.client.mac = {
    roles = [ "client" ];
    config.clients = {
      personal = {
        name = "subcog";
        domain = "subcog.swancloud.net";
        namespace = "personal";
        claude-code.mcp.enabled = true;
        claude-code.skill.enabled = true;
      };
      work = {
        name = "subcog-work";
        domain = "subcog.swancloud.net";
        namespace = "work";
        claude-code.mcp.enabled = true;
      };
    };
  };
}
```

## Key Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clients.<name>.name` | string | attr name | Integration identifier |
| `clients.<name>.domain` | string | — | FQDN of the subcog server |
| `clients.<name>.namespace` | string | `"default"` | Memory namespace for scoping |
| `clients.<name>.claude-code.skill.enabled` | bool | `true` | Install Claude Code agent skill |
| `clients.<name>.claude-code.mcp.enabled` | bool | `false` | Configure Claude Code MCP server |
| `clients.<name>.agent-deck.mcp.enabled` | bool | `false` | Add agent-deck MCP entry |
