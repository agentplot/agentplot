## Context

AgentPlot currently has two clanServices (linkding, microvm). Adding gno follows the established clanService pattern with server and client roles. gno is a TypeScript/Bun document search engine providing hybrid search (vector + FTS5), wiki-link knowledge graph, and read/write MCP tooling over Streamable HTTP transport.

The server will run on swancloud-srv (NixOS), while clients run on darwin workstations and VMs. The linkding service provides a mature reference for the role split, interface options, HM module delegation, and clan.core.vars patterns.

## Goals / Non-Goals

**Goals:**
- Deploy gno as a systemd service on NixOS with persistent storage
- Expose gno via Caddy reverse proxy at configurable domain (default: gno.swancloud.net)
- Configure document collections declaratively via Nix interface options
- Wire MCP endpoint into claude-code and agent-deck via HM module delegation
- Borgbackup integration for gno's sqlite database
- Follow the established clanService patterns from linkding

**Non-Goals:**
- Packaging gno itself (use upstream release or OCI image — not building from source)
- OIDC/auth for gno (single-user behind Tailscale, not internet-facing)
- Multi-instance client pattern (gno is a singleton service, unlike linkding's multi-client)
- Custom CLI wrapper (gno's MCP is the primary interface; no separate CLI tool needed)
- Web UI customization (use gno's built-in web UI as-is)

## Decisions

### 1. OCI container vs native systemd service

**Decision**: OCI container via podman (same as linkding).

**Rationale**: gno bundles Bun, node-llama-cpp, GGUF model files, and sqlite-vec. An OCI image encapsulates these heavy dependencies without polluting the NixOS closure. Consistent with the linkding pattern.

**Alternative considered**: Native Nix package — would require packaging Bun, node-llama-cpp, and model weights in Nix, which is complex and brittle for a TypeScript/ML stack.

### 2. Singleton client vs multi-client pattern

**Decision**: Single endpoint configuration (no `clients` attrset like linkding).

**Rationale**: gno is a centralized document search engine — there's one instance serving all collections. Unlike linkding where you might have personal vs business instances, gno serves a unified knowledge graph. Interface options are simpler: just domain, port, and MCP toggle flags.

**Alternative considered**: Multi-client attrset — unnecessary complexity for a singleton service.

### 3. Collection configuration

**Decision**: Collections defined in the server role's interface as `attrsOf` with `path` and `pattern` options. The server role generates the gno config file from these.

**Rationale**: Declarative collection management keeps all config in Nix. Collections define what document directories to index and which file patterns to include.

### 4. MCP transport

**Decision**: Streamable HTTP transport (not stdio). Client role configures the MCP endpoint URL rather than launching a subprocess.

**Rationale**: gno runs as a remote server, not a local process. The MCP client connects via HTTP to the gno instance. This means the client role needs `url` type MCP config, not `command` + `args`.

### 5. Storage and persistence

**Decision**: Bind-mount `/persist/gno` for sqlite databases and model cache. Borgbackup via existing patterns.

**Rationale**: Consistent with linkding's `/persist/linkding` pattern. sqlite-vec databases and FTS5 indexes are the primary state.

## Risks / Trade-offs

- **[Large OCI image]** → gno with embedded models may be 2-4 GB. Mitigation: model files cached on persistent volume, not baked into image on every update.
- **[GPU not available in container]** → CPU inference for BGE-M3 embedding and Qwen3 reranking. Mitigation: Q4_K_M quantization keeps latency acceptable for batch indexing; reranking is lightweight at 0.6B params.
- **[sqlite-vec single-writer]** → Concurrent writes could conflict. Mitigation: gno handles this internally with WAL mode; single-instance deployment means no multi-writer contention.
- **[Upstream gno stability]** → gno is relatively new. Mitigation: pin OCI image tag, borgbackup for data safety, container isolation limits blast radius.
