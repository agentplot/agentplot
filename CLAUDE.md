# CLAUDE.md

AgentPlot is an infrastructure-as-code framework for building **agent-optimized clanServices** — co-located infrastructure deployment, CLI packages, agent skills, and Home Manager module delegation, all built on Nix flakes.

## Build & Test

```bash
nix build .#linkding-cli          # Build a package
nix flake check                   # Evaluate/check the flake
nix-instantiate --eval tests/hmModules-composition.nix  # Smoke test
```

## Directory Map

```
services/           ← clanService definitions (start here for most work)
  linkding/           server+client: bookmark manager
  gno/                server+client: document search (hybrid RAG)
  qmd/                server+client: document search (advanced retrieval)
  subcog/             server+client: persistent agent memory
  ogham-mcp/          server+client: semantic memory (MCP)
  miniflux/           server+client: RSS reader
  paperless/          server+client: document management + OCR
  atomic/             server+client: personal knowledge base
  openclaw/           server+client: AI assistant gateway (microvm)
  obsidian/           client-only: knowledge management
  himalaya/           client-only: email client
  tana/               client-only: knowledge management
  microvm/            host+guest: hypervisor (not a typical service)
modules/            ← Shared NixOS/Darwin modules (agentplot adapter, OIDC, dashboards)
packages/           ← Dashboard packages (capabilities + fleet views)
tests/              ← Nix evaluation tests for module composition and delegation
openspec/           ← OpenSpec change tracking (artifact-driven workflow)
```

Each subdirectory with substantial conventions has its own CLAUDE.md — read it before working in that area.

## Flake Structure

**Inputs**: `agentplot-kit` (framework: mkClientTooling, caddy-cloudflare), `microvm`, `agent-skills-nix`, `nix-agent-deck`, `nix-openclaw`

**Outputs**:
- `clan.modules.*` — clanService definitions consumed by deployment inventories
- `nixosModules.agentplot` / `darwinModules.agentplot` — HM delegation adapter
- `packages.<system>.*` — standalone CLI packages (linkding-cli, miniflux-cli, paperless-cli)
- `lib.mk*Dashboard` / `lib.mk*Inventory` — dashboard builders for cross-machine views

## Related Repos

- `agentplot-kit` (`../agentplot-kit`) — Framework: mkClientTooling, caddy-cloudflare, secretspec, claude-code HM modules
- swancloud (`../../github_afterthought/swancloud`) — Deployment inventory consuming agentplot services
- llm-agents.nix (`../../github_afterthought/llm-agents.nix`) — Nix packages for qmd, gno, subcog (overlay: `pkgs.llm-agents.*`)

## OpenSpec Workflow

This repo uses OpenSpec for change management. Use `/opsx:` commands to create, implement, and archive changes. Each change produces artifacts: proposal → design → specs → tasks. Changes live in `openspec/changes/`.
