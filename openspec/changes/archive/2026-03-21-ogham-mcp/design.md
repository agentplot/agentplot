## Context

AgentPlot currently provides no persistent agent memory service. Agents lose context between sessions and across machines. ogham-mcp is an existing open-source MCP server (MIT license) that provides hybrid search, knowledge graphs, and cognitive decay — a strong fit for agent memory needs. It requires PostgreSQL + pgvector as its backing store and communicates via SSE transport.

The linkding clanService establishes the server/client role pattern with multi-client support, HM module delegation, and profile-scoped MCP configuration. ogham-mcp follows the same pattern but is simpler on the client side (no CLI wrapper needed — interaction is purely via MCP) and adds PostgreSQL database provisioning on the server side.

## Goals / Non-Goals

**Goals:**
- Deploy ogham-mcp as a systemd service on swancloud-srv via `uvx`
- Provision PostgreSQL database with pgvector extension for vector storage
- Expose SSE endpoint behind Caddy reverse proxy at ogham.swancloud.net
- Client role delegates MCP endpoint configuration into claude-code and agent-deck via HM modules
- Support partition-scoped memory via profiles (e.g., work vs personal memory spaces)
- Manage secrets (OpenAI API key, DB password) via clan.core.vars generators
- Back up PostgreSQL data via borgbackup state folders

**Non-Goals:**
- No CLI wrapper package — ogham-mcp is accessed exclusively via MCP protocol
- No OIDC authentication in v1 — SSE endpoint is network-internal only
- No multi-instance server support — single ogham-mcp deployment per server role
- No local/embedded mode — always connects to the shared SSE server
- No custom embedding model hosting — uses external API providers (OpenAI default)

## Decisions

### 1. Runtime: `uvx` instead of Nix-packaged Python

ogham-mcp is a rapidly evolving Python package. Using `uvx ogham-mcp` (via nixpkgs `uv`) for runtime avoids maintaining a Nix derivation for its Python dependency tree. The systemd service fetches/caches the package on first start.

**Alternative**: Package as a Nix flake input — rejected because ogham-mcp has no flake.nix and its dependency tree (pgvector, sentence-transformers) is complex to nixify.

### 2. PostgreSQL provisioned via NixOS services, not containerized

Use `services.postgresql` with pgvector extension directly on the host. This aligns with NixOS conventions, simplifies backup (borgbackup can target `/var/lib/postgresql`), and avoids container networking complexity.

**Alternative**: PostgreSQL in a container — rejected because it adds OCI orchestration overhead for a single-purpose database with no isolation benefit on a dedicated server.

### 3. Single-server model with partition scoping via profiles

Rather than multi-client configs (like linkding), ogham-mcp uses a single server endpoint. Memory isolation is achieved through ogham-mcp's built-in partition support, exposed via the client role's profile mechanism. Each profile maps to a partition name sent in MCP requests.

**Alternative**: Multiple ogham-mcp instances per partition — rejected because it wastes resources and the server already supports partitioning natively.

### 4. Client role uses `clients` attrset pattern (matching linkding)

Despite being simpler (no CLI, no multi-instance), the client role follows the same `clients` attrset pattern as linkding for consistency. Each client entry configures the MCP endpoint URL, API key, and enabled toolchains.

### 5. Embedding provider as interface option

The server role exposes `embeddingProvider` (openai/ollama/mistral/voyage) and related options (ollamaHost). This allows the deployment to choose embedding backends without modifying the service definition. Default is OpenAI text-embedding-3-small (512d).

## Risks / Trade-offs

- **[uvx network dependency]** → First start requires internet to fetch ogham-mcp package. Mitigation: systemd `Restart=on-failure` with delay; uv caches packages after first fetch.
- **[Embedding API cost]** → OpenAI embeddings incur per-token costs. Mitigation: configurable provider; can switch to self-hosted ollama.
- **[Single point of failure]** → All agent memory routes through one server. Mitigation: borgbackup for data recovery; PostgreSQL is reliable for this scale.
- **[pgvector version coupling]** → pgvector extension version must match PostgreSQL version in nixpkgs. Mitigation: pin to the nixpkgs PostgreSQL default; test on upgrade.
