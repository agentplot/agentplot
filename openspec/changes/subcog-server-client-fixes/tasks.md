## 1. Server storage env vars

- [x] 1.1 Replace `SUBCOG_DATABASE_URL` with `SUBCOG_STORAGE_BACKEND=postgresql` + `SUBCOG_STORAGE_CONNECTION_STRING` in `subcog-env` script
- [x] 1.2 Remove `path = [ pkgs.openssl ]` from `subcog-env` (now using ogham-mcp env file pattern with `let`/`in`)

## 2. Server LLM API key provisioning

- [x] 2.1 Add `llmProvider` enum option (anthropic/openai/ollama, default "anthropic") to server interface
- [x] 2.2 Add `llmModel` string option (default "") to server interface
- [x] 2.3 Add `needsApiKey` guard in perInstance `let` block
- [x] 2.4 Add prompted vars generator `subcog-llm-api-key` gated on `needsApiKey` (ogham pattern)
- [x] 2.5 Add `SUBCOG_LLM_PROVIDER`, conditionally `SUBCOG_LLM_API_KEY` and `SUBCOG_LLM_MODEL` to env file

## 3. Server JWT secret persistence

- [x] 3.1 Add `clan.core.vars.generators."subcog-jwt-secret"` with `share = true` and `openssl rand -base64 32`
- [x] 3.2 Replace ephemeral `/run/subcog.jwt` logic in `subcog-env` with read from vars path
- [x] 3.3 Add `clan.core.vars.generators."subcog-jwt-token"` with shell-based HS256 JWT signing

## 4. Client CLI envVars

- [x] 4.1 Add `envVars = client: { SUBCOG_DOMAIN = client.domain; }` to CLI capability

## 5. Client DB access and MCP JWT auth (blocked on agentplot-kit#3)

- [x] 5.1 Add shared secret mode to mkClientTooling in agentplot-kit (agentplot-kit#3)
- [x] 5.2 Wire `SUBCOG_STORAGE_CONNECTION_STRING` in CLI envVars using shared DB password
- [x] 5.3 Wire MCP `tokenFile` using shared JWT token from `subcog-jwt-token` generator

## 6. Spec updates

- [x] 6.1 Sync delta specs to main specs via `openspec sync`

## 7. Verification

- [x] 7.1 `nix flake check` passes
- [x] 7.2 `nix-instantiate --eval tests/hmModules-composition.nix` passes
