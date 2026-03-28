## Context

The subcog clanService server role uses `SUBCOG_DATABASE_URL` which does not exist in subcog's Rust codebase (0 GitHub code search hits). The correct env vars are `SUBCOG_STORAGE_BACKEND` + `SUBCOG_STORAGE_CONNECTION_STRING` (src/config/mod.rs:2320-2335). The server also lacks LLM API key configuration for enrichment/consolidation, and the JWT secret is ephemeral (regenerated on each boot via `/run/subcog.jwt`).

The client role's CLI wrapper has no env vars, so `subcog-<name>` runs without knowing the server domain. The MCP endpoint requires JWT bearer tokens but no token is wired to clients. The subcog CLI operates on local storage but supports remote PostgreSQL via `SUBCOG_STORAGE_CONNECTION_STRING`, enabling direct DB access from client machines.

JWT is mandatory for HTTP transport — `cmd_serve` unconditionally calls `with_jwt_from_env()` which errors without `SUBCOG_MCP_JWT_SECRET` (min 32 chars, 3+ character classes). Clients must provide HS256 JWTs with `sub`, `exp`, and `scopes` claims.

## Goals / Non-Goals

**Goals:**
- Fix server storage env vars to match upstream subcog binary
- Add LLM API key provisioning (prompted secret, gated on provider)
- Persist JWT secret across reboots via shared vars generator
- Pre-generate a signed JWT token for future client MCP auth
- Add `SUBCOG_DOMAIN` to client CLI wrapper for skill diagnostics

**Non-Goals:**
- Full client DB access wiring (blocked on agentplot-kit#3 shared secret mode)
- Full client MCP JWT auth wiring (same blocker)
- Changes to the subcog binary or upstream subcog behavior

## Decisions

**1. Use `SUBCOG_STORAGE_BACKEND` + `SUBCOG_STORAGE_CONNECTION_STRING` instead of `SUBCOG_DATABASE_URL`**

The old env var does not exist in subcog's source. The storage config module reads `SUBCOG_STORAGE_BACKEND` to select sqlite/postgresql/filesystem, and `SUBCOG_STORAGE_CONNECTION_STRING` for the PostgreSQL connection URL.

**2. Follow ogham-mcp pattern for LLM API key provisioning**

Add `llmProvider` enum (anthropic/openai/ollama) and `llmModel` string to the server interface. Use a prompted vars generator `subcog-llm-api-key` gated on `needsApiKey` (anthropic/openai need keys, ollama does not). This mirrors ogham-mcp's `embeddingProvider` + `ogham-embedding-api-key` pattern exactly.

**3. Move JWT secret from ephemeral `/run/subcog.jwt` to persistent shared vars generator**

The current boot-time generation loses the secret on reboot, invalidating any tokens issued against it. A `clan.core.vars.generators."subcog-jwt-secret"` with `share = true` persists across reboots and is accessible to client machines via clan vars sharing. Uses `openssl rand -base64 32` which satisfies subcog's entropy requirements (3+ character classes).

**4. Pre-generate a signed JWT token in a vars generator**

A second generator `subcog-jwt-token` creates an HS256 JWT with `{"sub":"agentplot","scopes":["*"],"exp":<10 years>}` signed with the shared secret. This token will be consumed by clients once agentplot-kit supports shared secret references. Shell-based JWT signing uses `openssl dgst -sha256 -hmac` with base64url encoding.

**5. Defer full client wiring to agentplot-kit#3**

mkClientTooling's `secret` capability only supports `prompted` (operator-entered) and `generated` (random per-client) modes. Neither can reference a server-side shared vars generator. Full client wiring (CLI DB access via shared password, MCP JWT via shared token) requires a new `mode = "shared"` in mkClientTooling. Tracked as agentplot-kit#3.

## Risks / Trade-offs

- **[JWT token generator uses shell-based signing]** — The `subcog-jwt-token` vars generator constructs JWTs manually via openssl/base64url shell commands. This is fragile but avoids adding a JWT CLI tool dependency. → Mitigation: The generator runs once at vars generation time, not at boot. If it produces an invalid token, regeneration is trivial (`clan vars generate`).

- **[10-year token expiry]** — The pre-signed JWT has a very long expiry for operational simplicity. → Mitigation: The token can be regenerated at any time by re-running the vars generator. The server's JWT secret rotation would also invalidate it.

- **[Client wiring blocked]** — Until agentplot-kit#3 lands, the client CLI can't access the remote DB and MCP auth won't work. → Mitigation: Server fixes are independent and immediately valuable. Client fixes are additive.
