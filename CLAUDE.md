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

### Server Role Conventions

- **No local PostgreSQL**: Server roles never define `services.postgresql`. Database provisioning happens on the host via `clan.core.postgresql` in the consuming inventory (e.g., swancloud).
- **DB host hardcoded**: Services connect to `10.0.0.1:5432` (bridge gateway) matching the linkding/paperless pattern.
- **DB passwords via env file**: Services needing PG use a `clan.core.vars.generators` shared password + oneshot env service (see ogham-mcp, subcog for pattern). Never put secrets in static `environment` blocks.
- **Caddy TLS**: All server roles reference `config.caddy-cloudflare.tls` from the agentplot-kit module (not a local copy).
- **Packages from overlays**: qmd and gno use `pkgs.llm-agents.qmd`/`pkgs.llm-agents.gno` via overlay, not flake inputs.

### Client Role Pattern (mkClientTooling)

All client roles use `mkClientTooling` from agentplot-kit. Do NOT hand-write client roles. The function generates interface, perInstance, HM delegation, vars generators, and target wiring from a capabilities declaration.

### HM Module Delegation

Services define Home Manager modules that accumulate into `agentplot.hmModules.<service>-<client>`. The `modules/agentplot.nix` adapter wires all accumulated modules into a single user's Home Manager config, allowing multiple services to coexist without conflicts.

### Key Directories

- `services/` — clanService definitions (each with `default.nix`, optional `packages/`, `skills/`)
- `modules/` — Shared NixOS/Darwin modules (agentplot adapter, oidc interface)
- `tests/` — Nix evaluation tests for module composition
- `openspec/` — OpenSpec change tracking (artifact-driven workflow)

## Flake Inputs

- `agentplot-kit` — Framework: mkClientTooling, caddy-cloudflare, HM modules
- `microvm` — MicroVM hypervisor (astro/microvm.nix)
- `agent-skills-nix`, `nix-agent-deck`, `nix-openclaw`

## Flake Outputs

- `clan.modules.{linkding,microvm,gno,qmd,subcog,ogham-mcp}` — clanService definitions
- `nixosModules.agentplot` / `darwinModules.agentplot` — HM delegation adapter
- `packages.<system>.linkding-cli` — CLI package

### mkClientTooling Patterns
- Skill keys MUST include serviceName: `${serviceName}-${clientNameId}` — bare clientNameId collides across services
- `writeShellApplication` runs shellcheck — use `VAR="$(cmd)"; export VAR` not `export VAR="$(cmd)"`
- `lib.isPath` returns false for derivations — check `builtins.isAttrs content && content ? outPath` for derivation paths
- `programs.claude-code.skills` values can be strings, paths, OR derivations (from mkSkillDir)

### Miniflux Service
- NixOS miniflux module types `CREATE_ADMIN`, `RUN_MIGRATIONS`, `OAUTH2_USER_CREATION` as integers, not strings
- `OAUTH2_OIDC_DISCOVERY_ENDPOINT` wants the issuer URL, NOT the full `/.well-known/openid-configuration` path
- `adminCredentialsFile` must contain `ADMIN_USERNAME=x` and `ADMIN_PASSWORD=x` lines
- DynamicUser can't read sops secrets (root:root 0440) — use a separate root oneshot to prepare env files
- EnvironmentFile paths validated BEFORE ExecStartPre — use `-` prefix for optional files

### Service State
- Use `clan.core.state.<name>.folders` for persistent state paths, not `services.borgbackup.jobs`
- `config ? services.borgbackup` is always true (NixOS declares the option) — not a valid guard

### Microvm Guest Conventions
- All guests need `networking.hostId = lib.mkForce "<unique-8-hex>"` to resolve microvm vs clan-core ZFS conflict
- Guests using llm-agents packages need `nixpkgs.overlays = [ inputs.llm-agents.overlays.default ]`

## Related Repos

- `agentplot-kit` (`../agentplot-kit`) — Framework: mkClientTooling, caddy-cloudflare, secretspec, claude-code HM modules
- swancloud (`../../github_afterthought/swancloud`) — Deployment inventory consuming agentplot services
- llm-agents.nix (`../../github_afterthought/llm-agents.nix`) — Nix packages for qmd, gno, subcog (overlay: `pkgs.llm-agents.*`)

## OpenSpec Workflow

This repo uses OpenSpec for change management. Use `/opsx:` commands to create, implement, and archive changes. Each change produces artifacts: proposal → design → specs → tasks. Changes live in `openspec/changes/`.
