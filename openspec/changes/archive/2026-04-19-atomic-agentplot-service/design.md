## Context

AgentPlot services deploy as clanService modules with server + optional client roles. Server roles use OCI containers, Caddy TLS via `config.caddy-cloudflare.tls`, clan vars for secrets, and `clan.core.state` for borgbackup. Client roles use `mkClientTooling` for CLI wrappers, skills, and HM delegation. Existing services (linkding, subcog, ogham-mcp, gno) establish the pattern.

Atomic is a Rust-based personal knowledge base with semantic vector search, wiki synthesis, and RAG chat. It ships official Docker images and stores all state in a single SQLite-backed data directory. Authentication is bearer token only (no OIDC) — tokens managed via `atomic-server token` CLI subcommands.

LLM provider configuration (OpenRouter, Ollama, etc.) is done through the web UI or API after deployment, not at the server config level.

## Goals / Non-Goals

**Goals:**
- Deploy Atomic as a microvm guest following the established agentplot service pattern
- Provide TLS-terminated HTTPS access via Caddy + Cloudflare DNS-01
- Auto-generate an admin bearer token via clan vars
- Declare persistent state for borgbackup
- Build directly in agentplot as a reusable clanService
- Expose MCP server via Tailscale for Darwin client access
- Provide a `client` role built on `mkClientTooling` that wires the Atomic MCP endpoint into Claude Code with a prompted bearer token

**Non-Goals:**
- OIDC integration (Atomic doesn't support external OIDC providers — bearer tokens only)
- PostgreSQL backend (SQLite is sufficient for single-user; avoids dependency on host postgres)
- LLM provider configuration at the Nix level (this is a web UI concern)
- Multi-instance support (single instance is sufficient)

## Decisions

### 1. All-in-one OCI image vs separate server + web images

**Decision:** Use the all-in-one `ghcr.io/kenforthewin/atomic:latest` image (bundles server + web UI in one container).

**Rationale:** The Docker Compose setup ships separate server and web containers with nginx in front. But Atomic also publishes an all-in-one image where the server serves the frontend directly. One container, one port, Caddy in front. No inter-container networking. The container uses its built-in defaults for data dir (`/data`), bind address (`0.0.0.0` internally — safe because the port is published only to the microvm's localhost and fronted by Caddy), and listener port (8081) — we map the host port via `ports = [ "${settings.port}:8081" ]` rather than passing CLI args.

**Alternative considered:** Two containers (server + web + nginx) — rejected as unnecessary complexity for a single-user deployment.

### 2. Bearer token provisioning

**Decision:** Generate admin token via clan vars generator at deploy time. Write it to a secret file, then use a oneshot systemd service to create the token via `atomic-server token create` on first boot.

**Rationale:** Follows the paperless pattern (secret generation + oneshot env service). The token needs to exist in the database, not just as an env var, so we need a post-start provisioning step.

**Alternative considered:** Manual token creation via web UI — rejected because it requires interactive setup and isn't reproducible.

### 3. Data directory and persistence

**Decision:** Bind-mount `/persist/atomic` → `/data` inside the container (the image's built-in data dir).

**Rationale:** Single directory contains the SQLite database and all state. Maps cleanly to `clan.core.state.atomic.folders`. Follows the `/persist/<service>` convention as paperless and linkding. We bind-mount onto the image's default path rather than overriding `--data-dir`, so no CLI args are needed.

### 4. IP allocation

**Decision:** 10.0.0.9 — next available on the microvm bridge.

**Rationale:** Sequential allocation: .1=host, .2=coredns, .3=kanidm, .4=linkding, .5=paperless, .6=openclaw, .7=ogham, .8=subcog, .9=atomic.

### 5. Memory allocation

**Decision:** 2048 MB RAM for the microvm guest.

**Rationale:** Atomic's Rust backend is lightweight, but vector search operations and the embedded SQLite with sqlite-vec extensions need headroom. 2GB is conservative — can be tuned after observing real usage. Linkding runs fine on 512MB; paperless uses 5120MB due to OCR/Tika. Atomic should land between them.

## Risks / Trade-offs

**[Upstream image instability]** → Use `:latest` tag, matching the linkding pattern. Pin to a specific tag if stability issues arise.

**[Token provisioning race]** → The oneshot service that creates the bearer token must wait for the Atomic server to be ready. Use `ExecStartPre` with a health check loop (`/health` endpoint) before running `token create`. → Mitigation: systemd `After=` ordering + health check wait.

**[No OIDC]** → Bearer tokens are less ergonomic than SSO. Acceptable for a personal single-user service. If Atomic adds OIDC support upstream, the module can be extended.

**[SQLite on microvm tmpfs]** → The `/persist` mount must be on a real filesystem (virtiofs to host ZFS), not tmpfs. This is already the pattern for all other services — just verify the mount is wired correctly.

**[LLM API keys in Atomic's database]** → LLM provider config (API keys for OpenRouter etc.) lives in Atomic's SQLite database, configured via web UI. These are backed up with the data dir but aren't managed by clan vars. Acceptable trade-off — these keys are rotatable and the database is encrypted at rest via sops/borgbackup.

## Migration Plan

1. Create `services/atomic/default.nix` in agentplot with server role
2. Export as `clan.modules.atomic` in `flake.nix`
3. In swancloud: add machine entry + inventory wiring in `clan.nix`, DNS record
4. `clan vars generate` to create the bearer token secret
5. `clan machines update swancloud-srv` to deploy
6. Bootstrap age key on first boot (standard microvm guest procedure)
7. Configure LLM provider via web UI
8. Verify: health endpoint, TLS, bearer token auth, MCP access via Tailscale

**Rollback:** Remove machine from swancloud `clan.nix`, redeploy. Data persists on host ZFS until manually cleaned.

## Resolved Questions

- **FQDN:** `atomic.swancloud.net` (set in consuming inventory, not in the service module)
- **Image tag:** `:latest` — matches linkding pattern
- **MCP exposure:** Route via Tailscale to Darwin machines for agent integration
