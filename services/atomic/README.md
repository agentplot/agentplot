# atomic

Atomic personal knowledge base with semantic search, wiki synthesis, and RAG chat.

**Upstream:** [kenforthewin/atomic-server](https://github.com/kenforthewin/atomic-server)

## Benefits

- Linked-data knowledge base with built-in semantic search and RAG chat
- MCP endpoint gives agents direct read/write access to your knowledge graph
- SQLite-backed with zero external database dependencies
- Automatic bearer token provisioning for secure agent authentication

## Roles

| Role | Description |
|------|-------------|
| server | Atomic server (OCI container + Caddy, SQLite-backed) |
| client | Atomic agent tooling (MCP endpoint config, HM delegation) |

### Server

Deploys the Atomic server as an OCI container (`ghcr.io/kenforthewin/atomic-server`) with:

- **Podman container** on the configured port (default 8080) with SQLite storage at `/persist/atomic`
- **Caddy reverse proxy** with Cloudflare TLS termination
- **Bearer token provisioning** via a oneshot service that creates an admin token inside the container using `podman exec`
- **Borgbackup state** for `/persist/atomic`

### Client

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| MCP | HTTP MCP endpoint with bearer token auth |
| Secret | Shared admin token from server generator |

**Available targets:** `claude-code.mcp`, `agent-deck.mcp`

## Example Inventory

```nix
{
  services.atomic.server.swan = {
    roles = [ "server" ];
    config.domain = "atomic.swancloud.net";
  };

  services.atomic.client.mac = {
    roles = [ "client" ];
    config.clients = {
      main = {
        domain = "atomic.swancloud.net";
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
| `domain` (server) | string | -- | FQDN for the Atomic instance |
| `port` (server) | port | `8080` | Internal HTTP port for the Atomic server |
| `clients.<name>.domain` | string | -- | FQDN of the Atomic server for this client |
