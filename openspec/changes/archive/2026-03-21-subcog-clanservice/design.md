## Context

AgentPlot currently has two clanServices: linkding (bookmark manager) and microvm (VM guests). Subcog is a Rust-based persistent memory system that provides hybrid search (vector + keyword + graph), entity-centric knowledge graphs, and namespace-scoped retention policies via ~40+ MCP tools. It uses PostgreSQL + pgvector as its unified backend and fastembed-rs for local embedding (all-MiniLM-L6-v2, 384d ONNX).

The subcog server needs to run on swancloud-srv alongside other services, with clients on darwin workstations and VM guests connecting via HTTP with JWT auth.

## Goals / Non-Goals

**Goals:**
- Declarative deployment of subcog server with PostgreSQL + pgvector, JWT auth, TLS, and backups
- Client-side MCP endpoint wiring via HM delegation (claude-code, agent-deck)
- Follow established clanService patterns (linkding as reference)
- Agent skill (SKILL.md) documenting subcog's MCP tools

**Non-Goals:**
- Building subcog from source in Nix (use pre-built binary or cargo fetch — deferred to packaging decision)
- OIDC integration (JWT-only for now; OIDC can be added later like linkding)
- Custom CLI wrapper (subcog exposes MCP directly over HTTP, no restish/OpenAPI pattern needed)
- Multi-instance server support (single instance per host is sufficient)

## Decisions

### 1. HTTP MCP transport (not stdio)

Subcog serves MCP over HTTP with JWT auth natively. Unlike linkding which wraps a REST API with restish+stdio MCP, subcog's MCP endpoint is the primary interface. Client roles configure `url`-based MCP servers pointing to the HTTP endpoint.

**Alternative**: Wrap in stdio — rejected because subcog already provides HTTP MCP natively, and HTTP allows shared server across agents.

### 2. Single-client interface (not multi-client attrsOf)

Linkding uses `clients = attrsOf clientSubmodule` to support multiple named clients (personal, work). Subcog serves a single memory namespace per deployment, so the client role uses a flat interface without the clients attrSet layer.

**Alternative**: Multi-client like linkding — rejected because subcog namespacing is handled within subcog itself (namespace-scoped retention), not at the infrastructure level.

### 3. PostgreSQL + pgvector via NixOS services

Use `services.postgresql` with pgvector extension, managed declaratively. Subcog connects locally via Unix socket (no network password needed for local connections).

**Alternative**: External/managed PostgreSQL — rejected to keep deployment self-contained and consistent with the all-declarative pattern.

### 4. JWT secret via clan.core.vars.generators

Generate a shared JWT secret using `openssl rand -hex 32`. Both server and client roles reference the same secret. Server uses it to validate tokens; clients use it to authenticate.

### 5. borgbackup for PostgreSQL dumps

Follow the same pattern as other services: periodic `pg_dump` to a borg repository. The database is the only stateful component.

### 6. Caddy reverse proxy via caddy-cloudflare shared module

Reuse `modules/caddy-cloudflare.nix` for TLS termination with DNS-01 ACME, matching the linkding pattern.

## Risks / Trade-offs

- **[Binary packaging]** Subcog is a Rust binary not yet in nixpkgs. → Mitigation: Initially use `fetchurl` for a pre-built release binary or `buildRustPackage`/`crane` to build from source. Package definition lives in `services/subcog/packages/`.
- **[pgvector version coupling]** Subcog requires pgvector for vector search. → Mitigation: Pin pgvector extension version alongside PostgreSQL version in the module.
- **[JWT secret distribution]** Server and clients must share the same JWT secret. → Mitigation: Use clan.core.vars with `share = true` so the secret propagates to all machines in the clan.
- **[Embedding model size]** fastembed-rs downloads the ONNX model on first run (~90MB). → Mitigation: This is handled by subcog internally; document in SKILL.md that first startup may be slower.
