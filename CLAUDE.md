# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AgentPlot is an infrastructure-as-code framework for building **agent-optimized clanServices** — co-located infrastructure deployment, CLI packages, agent skills, and Home Manager module delegation, all built on Nix flakes.

## Build & Test Commands

```bash
# Build a package
nix build .#linkding-cli

# Evaluate/check the flake
nix flake check

# Run the HM module composition smoke test
nix-instantiate --eval tests/hmModules-composition.nix

# Enter a dev shell (if defined)
nix develop
```

## Architecture

### clanService Pattern

Each service in `services/` defines one or more roles (e.g., server/client, host/guest, or other service-specific roles). Roles encapsulate the NixOS/Darwin modules, packages, skills, and configuration relevant to that aspect of the service.

### HM Module Delegation

Services define Home Manager modules that accumulate into `agentplot.hmModules.<service>-<client>`. The `modules/agentplot.nix` adapter wires all accumulated modules into a single user's Home Manager config, allowing multiple services to coexist without conflicts.

### Key Directories

- `services/` — clanService definitions (each with `default.nix`, optional `packages/`, `skills/`)
- `modules/` — Shared NixOS/Darwin modules (agentplot adapter, caddy-cloudflare)
- `tests/` — Nix evaluation tests for module composition
- `openspec/` — OpenSpec change tracking (artifact-driven workflow)

## Flake Inputs

- `agentplot-kit` — Framework for building clanServices
- `microvm` — MicroVM hypervisor (astro/microvm.nix)
- `agent-skills-nix`, `nix-agent-deck`, `nix-openclaw`

## Flake Outputs

- `clan.modules.{linkding,microvm}` — clanService definitions
- `nixosModules.agentplot` / `darwinModules.agentplot` — HM delegation adapter
- `packages.<system>.linkding-cli` — CLI package

## OpenSpec Workflow

This repo uses OpenSpec for change management. Use `/opsx:` commands to create, implement, and archive changes. Each change produces artifacts: proposal → design → specs → tasks. Changes live in `openspec/changes/`.
