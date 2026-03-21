## Context

AgentPlot needs a document search capability for indexed collections of local files (notes, docs, code). qmd by Tobias Lutke provides SOTA hybrid retrieval: BM25 full-text + cosine vector search with EmbeddingGemma-300M, custom finetuned Qwen3-1.7B query expansion, Qwen3-Reranker-0.6B cross-encoder reranking, and strong signal bypass (BM25 >= 0.85). It exposes 4 read-only MCP tools via Streamable HTTP transport.

The upstream repo has a `flake.nix`, making Nix integration straightforward. qmd uses SQLite + sqlite-vec for storage, with FTS5 for full-text and cosine HNSW for vector search.

## Goals / Non-Goals

**Goals:**
- Deploy qmd as a systemd service on swancloud-srv with Streamable HTTP transport
- Expose qmd via Caddy reverse proxy at qmd.swancloud.net
- Configure document collections declaratively via clanService interface
- Provide client-side MCP HTTP endpoint delegation to claude-code and agent-deck
- Include borgbackup integration for qmd's SQLite databases
- Follow established clanService patterns (linkding as reference)

**Non-Goals:**
- Custom CLI wrapper package (qmd's MCP tools are the primary interface; no REST API to wrap)
- OIDC authentication (qmd is a local/private service, not multi-tenant)
- Agent skills (MCP tools are sufficient; no SKILL.md needed)
- Write operations (qmd tools are read-only; indexing is server-side)
- Multi-instance client support (unlike linkding, there's one qmd server; simple client config)

## Decisions

### 1. Streamable HTTP transport over stdio

qmd supports Streamable HTTP mode (`--transport http --port 8423`). The client connects via HTTP URL rather than spawning a subprocess.

**Rationale**: The server runs on swancloud-srv; clients on Darwin machines and VMs connect remotely. HTTP transport is the only viable option for remote MCP access.

**Alternative considered**: stdio transport with SSH tunneling — rejected as overly complex for a read-only search service.

### 2. Single-instance client (no attrsOf clients)

Unlike linkding which supports multiple named client instances, qmd uses a single server URL. The client interface takes `domain` and `port` directly.

**Rationale**: qmd is a single-instance search engine. Multiple collections are configured server-side, not per-client. This simplifies the client role significantly.

### 3. Upstream flake input for qmd package

Add qmd as a flake input and use its default package rather than packaging it ourselves.

**Rationale**: Upstream maintains a `flake.nix` with Bun/Node.js runtime, model downloads, and native dependencies (sqlite-vec, node-llama-cpp). Maintaining a parallel package would be high-effort.

### 4. Collection configuration via interface options

Server interface exposes `collections` as `attrsOf` with `path`, `pattern`, and `exclude` options. These map to qmd's collection config.

**Rationale**: Declarative collection management fits the Nix model. The server systemd service generates qmd's config from these options.

### 5. Caddy reverse proxy with cloudflare TLS

Follow the existing caddy-cloudflare pattern used by linkding for HTTPS termination.

**Rationale**: Consistent infrastructure pattern across services. DNS already managed via Cloudflare.

### 6. Borgbackup for SQLite databases

Add qmd's data directory to borgbackup paths, following the pattern for persistent data.

**Rationale**: qmd stores indexed data in SQLite databases. While re-indexing is possible, backup preserves the indexed state and avoids costly re-embedding.

## Risks / Trade-offs

- **[Large model downloads on first run]** → qmd downloads EmbeddingGemma-300M, Qwen3-1.7B, and Qwen3-Reranker-0.6B on first start. Mitigation: systemd service has a long timeout; models are cached in the data directory and backed up.
- **[Upstream flake stability]** → Depending on upstream flake.nix means tracking their changes. Mitigation: Pin the input to a specific commit/tag; update deliberately.
- **[Resource usage]** → Three quantized models loaded in memory for query expansion + reranking. Mitigation: Q8 quantization keeps memory reasonable; swancloud-srv has sufficient resources.
- **[No authentication]** → qmd exposed on qmd.swancloud.net without auth. Mitigation: Read-only tools, private network, Cloudflare access rules can be added later if needed.
