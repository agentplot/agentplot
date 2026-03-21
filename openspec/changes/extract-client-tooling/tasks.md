## 1. agentplot-kit: mkClientTooling Core

- [ ] 1.1 Create `lib/mkClientTooling.nix` in agentplot-kit with the function skeleton: accepts `{ serviceName, capabilities, extraClientOptions }`, returns `{ interface; perInstance; }`
- [ ] 1.2 Implement target registry: define each target's required capabilities and wiring function (claude-code-skill, claude-code-mcp, claude-code-profile, agent-skills, agent-deck-mcp, agent-deck-skill, openclaw-skill)
- [ ] 1.3 Implement `clientSubmodule` generation: dynamically build options from target registry (only targets whose capabilities are present get enable flags) plus `name` option plus `extraClientOptions`
- [ ] 1.4 Implement `interface` generation: `options.clients = attrsOf clientSubmodule`
- [ ] 1.5 Implement `perInstance` generation: iterate clients, build per-client HM modules with delegation wiring, register in `agentplot.hmModules.${serviceName}-${clientName}`
- [ ] 1.6 Implement secret management: generate clan vars generators per client from `capabilities.secret` with `agentplot-${serviceName}-${clientName}-${secretName}` naming
- [ ] 1.7 Implement CLI wrapper generation: `writeShellApplication` per client from `capabilities.cli`
- [ ] 1.8 Implement skill content substitution: read template, replace service name with client name in frontmatter and body
- [ ] 1.9 Add `mkClientTooling` to existing `lib` output in agentplot-kit `flake.nix` (alongside existing `lib.envContract`)

## 2. nix-agent-deck: Skill Pool HM Option

- [ ] 2.1 Add `programs.agent-deck.skillSources` option (attrsOf path) to `modules/agent-deck.nix` in nix-agent-deck
- [ ] 2.2 Implement HM activation: generate `home.file.".agent-deck/skills/pool/${name}".source` for each entry
- [ ] 2.3 Add test for skillSources option in nix-agent-deck

## 3. Refactor linkding Client Role

- [ ] 3.1 Rewrite `services/linkding/default.nix` client role to use `mkClientTooling` with capabilities: `skill = ./skills/SKILL.md`, `cli = { package = ./packages/linkding-cli; ... }`, `secret = { name = "api-token"; mode = "prompted"; }`, `mcp = null` (linkding has no MCP server)
- [ ] 3.2 Fix openclaw delegation: change `content` field to `body` and add `source` field (existing bug — `content` is not a valid openclaw skill field)
- [ ] 3.3 Remove `claude-tools.enabled` option and all claude-tools delegation code
- [ ] 3.4 Verify existing tests still pass after refactor

## 4. Refactor ogham-mcp Client Role

- [ ] 4.1 Rewrite `services/ogham-mcp/default.nix` client role to use `mkClientTooling` with capabilities: `skill = ./skills/SKILL.md`, `mcp = { type = "sse"; urlTemplate = ... }`, `secret = { name = "api-key"; mode = "prompted"; }`
- [ ] 4.2 Add `extraClientOptions`: `url` (SSE endpoint)

## 5. Refactor subcog Client Role

- [ ] 5.1 Rewrite `services/subcog/default.nix` client role to use `mkClientTooling` with capabilities: `skill = ./skills/SKILL.md`, `mcp = { type = "http"; urlTemplate = ... }`, `secret = { name = "jwt-secret"; mode = "generated"; }`
- [ ] 5.2 Add `extraClientOptions`: `domain`, `namespace`

## 6. Refactor gno Client Role

- [ ] 6.1 Rewrite `services/gno/default.nix` client role to use `mkClientTooling` with capabilities: `mcp = { type = "http"; urlTemplate = ... }`, `skill = null`, `cli = null`
- [ ] 6.2 Add `extraClientOptions`: `domain`

## 7. Refactor qmd Client Role

- [ ] 7.1 Rewrite `services/qmd/default.nix` client role to use `mkClientTooling` with capabilities: `mcp = { type = "http"; urlTemplate = ... }`, `skill = null`, `cli = null`
- [ ] 7.2 Add `extraClientOptions`: `domain`

## 8. Remove claude-tools Dependency

- [ ] 8.1 Remove `claude-plugins-nix` from agentplot `flake.nix` inputs
- [ ] 8.2 Remove any remaining `claude-tools` references from tests
- [ ] 8.3 Remove `claude-tools-delegation` spec from `openspec/specs/`

## 9. Service READMEs

- [ ] 9.1 Create `services/linkding/README.md` — bookmark manager, server + client roles, skill/CLI capabilities, example inventory
- [ ] 9.2 Create `services/ogham-mcp/README.md` — agent memory server, server + client roles, skill/MCP capabilities, example inventory
- [ ] 9.3 Create `services/subcog/README.md` — agent memory (Rust), server + client roles, skill/MCP capabilities, example inventory
- [ ] 9.4 Create `services/gno/README.md` — document RAG with wiki-link graph, server + client roles, MCP-only capabilities, example inventory
- [ ] 9.5 Create `services/qmd/README.md` — document RAG with SOTA hybrid search, server + client roles, MCP-only capabilities, example inventory
- [ ] 9.6 Create `services/microvm/README.md` — microVM host/guest infrastructure, no client role

## 10. Tests and Validation

- [ ] 10.1 Create `tests/mkClientTooling-composition.nix` — verify two services using mkClientTooling compose their HM modules without conflict
- [ ] 10.2 Update existing delegation tests to work with new mkClientTooling-generated structure
- [ ] 10.3 Run `nix flake check` on both agentplot-kit and agentplot to verify no regressions
