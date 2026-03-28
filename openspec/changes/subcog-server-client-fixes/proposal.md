## Why

The subcog server role uses `SUBCOG_DATABASE_URL` which does not exist in subcog's codebase (confirmed via GitHub code search: 0 results). The correct env vars are `SUBCOG_STORAGE_BACKEND` + `SUBCOG_STORAGE_CONNECTION_STRING`. The server also lacks LLM API key provisioning needed for enrichment/consolidation features, and the JWT secret is ephemeral (lost on reboot). The client role has no CLI env vars and no MCP JWT auth wiring.

## What Changes

- **Server**: Replace `SUBCOG_DATABASE_URL` with `SUBCOG_STORAGE_BACKEND=postgresql` + `SUBCOG_STORAGE_CONNECTION_STRING`
- **Server**: Add `llmProvider`/`llmModel` interface options with prompted API key vars generator (gated on provider needing a key)
- **Server**: Move JWT secret from ephemeral `/run/subcog.jwt` to persistent shared vars generator
- **Server**: Add pre-signed JWT token vars generator for future client MCP auth
- **Client**: Add `SUBCOG_DOMAIN` envVar to CLI wrapper for skill diagnostics
- **Client**: Wire DB password and MCP JWT token through mkClientTooling shared secret mode (blocked on agentplot-kit#3)

## Capabilities

### New Capabilities

### Modified Capabilities
- `subcog-server`: Storage env vars change from `SUBCOG_DATABASE_URL` to `SUBCOG_STORAGE_BACKEND` + `SUBCOG_STORAGE_CONNECTION_STRING`. New interface options for LLM provider/model. JWT secret moves from ephemeral to persistent shared vars generator. LLM API key generator added.
- `subcog-client`: CLI wrapper gains `SUBCOG_DOMAIN` envVar. Full DB access and MCP JWT auth deferred to agentplot-kit shared secret support.

## Impact

- `services/subcog/default.nix` — server and client role changes
- `openspec/specs/subcog-server/spec.md` — update env var requirements
- `openspec/specs/subcog-client/spec.md` — update client capabilities
- Upstream dependency: agentplot-kit#3 (shared secret mode for mkClientTooling) blocks full client wiring
