# ogham-mcp

Persistent agent memory server with hybrid search (semantic + full-text), knowledge graph, progressive compression, and cognitive decay.

**Upstream:** ogham-mcp (PyPI, via `uvx`)

## Roles

### Server

Deploys ogham-mcp as a systemd service with PostgreSQL/pgvector backend and Caddy reverse proxy. Supports multiple embedding providers (OpenAI, Ollama, Mistral, Voyage).

### Client

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| Skill | MCP-oriented skill describing available memory tools |
| MCP | SSE endpoint for MCP tool access |
| Secret | Prompted API key per client |

**Available targets:** `claude-code.skill`, `claude-code.mcp`, `claude-code.profiles`, `agent-skills`, `agent-deck.mcp`, `agent-deck.skill`, `openclaw.skill`

## Example Inventory

```nix
{
  services.ogham-mcp.server.swan = {
    roles = [ "server" ];
    config = {
      domain = "ogham.swancloud.net";
      embeddingProvider = "openai";
    };
  };

  services.ogham-mcp.client.mac = {
    roles = [ "client" ];
    config.clients = {
      personal = {
        name = "ogham-mcp";
        url = "https://ogham.swancloud.net";
        claude-code.skill.enabled = true;
        claude-code.mcp.enabled = true;
        agent-deck.mcp.enabled = true;
      };
    };
  };
}
```

## Key Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clients.<name>.name` | string | attr name | Integration identifier |
| `clients.<name>.url` | string | — | SSE endpoint URL |
| `clients.<name>.claude-code.skill.enabled` | bool | `true` | Install Claude Code agent skill |
| `clients.<name>.claude-code.mcp.enabled` | bool | `false` | Configure Claude Code MCP server |
| `clients.<name>.agent-deck.mcp.enabled` | bool | `false` | Add agent-deck MCP entry |
| `clients.<name>.agent-skills.enabled` | bool | `false` | Distribute skill via agent-skills |
| `clients.<name>.openclaw.skill.enabled` | bool | `false` | Add OpenClaw skill |
| `clients.<name>.agent-deck.skill.enabled` | bool | `false` | Add skill to agent-deck pool |
