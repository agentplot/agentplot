## Why

Agents need structured access to project documentation, notes, and knowledge bases with semantic search, wiki-link graph traversal, and write-back capability. Currently there is no clanService providing document RAG with MCP integration. gno fills this gap as a self-hosted document search engine with hybrid search (vector + FTS), knowledge graph via wiki-links, and full read/write MCP tooling.

## What Changes

- Add new `gno` clanService under `services/gno/` with server and client roles
- Server role: systemd service running gno (TypeScript/Bun) in HTTP/SSE mode, sqlite-vec + FTS5 storage, borgbackup integration, Caddy reverse proxy with DNS at gno.swancloud.net
- Client role: MCP HTTP endpoint configuration, HM module delegation for claude-code.mcp.enabled and agent-deck.mcp.enabled
- Server indexes configured document collections (attrsOf with path + glob pattern)
- Embedding via BGE-M3 Q4_K_M (node-llama-cpp, 1024d local), reranking via Qwen3-Reranker-0.6B
- 19 MCP tools for read + write operations over Streamable HTTP transport
- Web UI with graph visualization

## Capabilities

### New Capabilities
- `gno-server`: Server-side deployment — systemd service, sqlite-vec/FTS5 storage, collection indexing, borgbackup, Caddy reverse proxy, DNS
- `gno-client`: Client-side MCP configuration — endpoint wiring for claude-code and agent-deck, HM module delegation

### Modified Capabilities

_None — this is a new service with no changes to existing specs._

## Impact

- New `services/gno/` directory with `default.nix` and optional `packages/`, `skills/`
- `flake.nix` gains `clan.modules.gno` clanService export
- New HM modules accumulated via `agentplot.hmModules.gno-client`
- Server role adds systemd, Caddy, borgbackup NixOS config for gno deployment
- Port 8422 used for gno HTTP service
- Dependencies: Bun runtime, node-llama-cpp (for embeddings), sqlite-vec extension
