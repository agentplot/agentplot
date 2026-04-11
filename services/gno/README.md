# gno

Document search engine with hybrid RAG, wiki-link graph traversal, and MCP tooling for structured document retrieval.

**Upstream:** [nicepkg/gno](https://github.com/nicepkg/gno)

## Benefits

- Hybrid RAG with wiki-link graph traversal for context-aware document retrieval that follows relationships between documents
- Semantic document search across named collections with configurable glob patterns
- MCP integration gives agents direct access to structured document search and retrieval
- CLI and skill support for interactive and automated workflows alongside MCP tooling

## Roles

| Role | Description |
|------|-------------|
| **server** | OCI container with Caddy reverse proxy, named document collections |
| **client** | Agent tooling via `mkClientTooling` (CLI, skills, MCP endpoint, HM delegation) |

### Server

Deploys gno as an OCI container with Caddy reverse proxy. Supports named document collections with configurable glob patterns, bind-mounted from the host.

### Client

Provides MCP-only agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| MCP | HTTP Streamable endpoint for document search and retrieval |

**Available targets:** `claude-code.mcp`, `claude-code.profiles`, `agent-deck.mcp`

gno has no skill or CLI — interaction is purely via MCP tools.

## Example Inventory

```nix
{
  services.gno.server.swan = {
    roles = [ "server" ];
    config = {
      domain = "gno.swancloud.net";
      collections = {
        wiki = {
          path = "/data/wiki";
          pattern = "**/*.md";
        };
        notes = {
          path = "/data/notes";
        };
      };
    };
  };

  services.gno.client.mac = {
    roles = [ "client" ];
    config.clients = {
      docs = {
        name = "gno";
        domain = "gno.swancloud.net";
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
| `clients.<name>.domain` | string | — | FQDN of the gno server |
| `clients.<name>.claude-code.mcp.enabled` | bool | `false` | Configure Claude Code MCP server |
| `clients.<name>.agent-deck.mcp.enabled` | bool | `false` | Add agent-deck MCP entry |
