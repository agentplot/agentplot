## 1. Test Infrastructure

- [x] 1.1 Create `tests/agent-deck-mcp-delegation.nix` with stub for `programs.agent-deck.mcps` option (type: `attrsOf (attrsOf anything)`)
- [x] 1.2 Create mock HM modules simulating linkding client role output with `agent-deck.mcp.enabled = true`

## 2. Single-Client Validation

- [x] 2.1 Add assertion: single client produces `programs.agent-deck.mcps.<name>` with `command`, `args`, `env` keys
- [x] 2.2 Add assertion: client with `agent-deck.mcp.enabled = false` produces no entry in `mcps`

## 3. Multi-Client Composition

- [x] 3.1 Add mock for second client ("linkding-biz") with distinct base_url and agent-deck MCP enabled
- [x] 3.2 Add assertion: two clients produce exactly two distinct entries in `programs.agent-deck.mcps`
- [x] 3.3 Add assertion: mixed enablement (one true, one false) produces only the enabled entry

## 4. Config Structure Validation

- [x] 4.1 Add assertions verifying `command` is a string containing `/bin/`, `args` is a list, `env` is an attrset
- [x] 4.2 Add assertion verifying `env.LINKDING_BASE_URL` and `env.LINKDING_API_TOKEN_FILE` are present and correct

## 5. Verify and Finalize

- [x] 5.1 Run `nix-instantiate --eval tests/agent-deck-mcp-delegation.nix` and confirm PASS
- [x] 5.2 Run existing test `nix-instantiate --eval tests/hmModules-composition.nix` to confirm no regressions
