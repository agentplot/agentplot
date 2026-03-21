# qmd

Document search engine with SOTA hybrid retrieval combining dense vectors, sparse BM25, query expansion, and cross-encoder reranking.

**Upstream:** [tobi/qmd](https://github.com/tobi/qmd)

## Roles

### Server

Deploys qmd as a systemd service with Caddy reverse proxy. Supports named document collections with configurable glob patterns and exclusion rules.

### Client

Provides MCP-only agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| MCP | HTTP Streamable endpoint for document search and retrieval |

**Available targets:** `claude-code.mcp`, `claude-code.profiles`, `agent-deck.mcp`

qmd has no skill or CLI — interaction is purely via MCP tools.

## Example Inventory

```nix
{
  services.qmd.server.swan = {
    roles = [ "server" ];
    config = {
      domain = "qmd.swancloud.net";
      collections = {
        wiki = {
          path = "/data/wiki";
          pattern = "**/*.md";
          exclude = [ "**/node_modules/**" ];
        };
      };
    };
  };

  services.qmd.client.mac = {
    roles = [ "client" ];
    config.clients = {
      docs = {
        name = "qmd";
        domain = "qmd.swancloud.net";
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
| `clients.<name>.domain` | string | — | FQDN of the qmd server |
| `clients.<name>.claude-code.mcp.enabled` | bool | `false` | Configure Claude Code MCP server |
| `clients.<name>.agent-deck.mcp.enabled` | bool | `false` | Add agent-deck MCP entry |
