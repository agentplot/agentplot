## Context

Four agentplot clanServices (ogham-mcp, qmd, subcog, gno) exist but have never been deployed. Before deployment, their server roles need fixes to match the established patterns used by linkding and paperless in swancloud.

Client roles have already been refactored to use `mkClientTooling` from agentplot-kit (extract-client-tooling change). Only server roles need work.

Current issues:
- ogham-mcp and subcog define `services.postgresql` in their server roles — guests should never run their own PostgreSQL
- gno uses an OCI/Podman container — unnecessary since `llm-agents.nix` packages gno with bun2nix
- qmd references a dedicated `qmd` flake input — should use `pkgs.llm-agents.qmd` from the overlay
- subcog references `${pkgs.subcog}/bin/subcog` but this package doesn't exist yet
- ogham-mcp uses `uvx ogham-mcp` (fetches from PyPI at runtime) — acceptable for now
- `caddy-cloudflare.nix` is duplicated across repos instead of living in agentplot-kit

## Goals / Non-Goals

**Goals:**
- Fix all four server roles so they're deployment-ready
- Consolidate caddy-cloudflare module in agentplot-kit
- Remove redundant qmd flake input

**Non-Goals:**
- Swancloud deployment (tracked in swancloud's `deploy-agentplot-services` change)
- Refactoring client roles (already done via extract-client-tooling)
- Packaging subcog as a Nix derivation (prerequisite, tracked separately)
- Making ogham-mcp reproducible (currently uses `uvx` for runtime fetch)

## Decisions

### D1: caddy-cloudflare lives in agentplot-kit

**Decision**: Move to `agentplot-kit/modules/caddy-cloudflare.nix`, export as `nixosModules.caddy-cloudflare`.

**Rationale**: Every service with a Caddy server role needs this module. agentplot-kit is the framework layer and already exports shared modules (secretspec, claude-code, mkClientTooling). The swancloud-specific text ("for swancloud.net") in the prompt description will be generalized.

**Alternative considered**: Keep in agentplot alongside services. Rejected — caddy-cloudflare is service-agnostic infrastructure.

### D2: Remove PostgreSQL from ogham-mcp and subcog server roles

**Decision**: Strip all `services.postgresql` configuration. Hardcode `10.0.0.1` as the database host in environment config, matching how linkding hardcodes `LD_DB_HOST = "10.0.0.1"`.

**Rationale**: The established pattern is: host runs shared PostgreSQL, guests connect over the bridge. Guests never touch `services.postgresql`. The consuming inventory provisions database/user/password on the host.

**Alternative considered**: Making `postgresHost` configurable with conditional local PG. Rejected — creates two code paths, doesn't match how any other service works.

### D3: gno uses bun2nix package from llm-agents.nix overlay

**Decision**: Replace `virtualisation.oci-containers.containers.gno` with `systemd.services.gno` running `pkgs.llm-agents.gno`.

**Rationale**: llm-agents.nix has a fully working bun2nix build with GPU support, SQLite linking, and NixOS-specific patches. Collection paths map directly on the filesystem instead of through container bind-mounts.

### D4: qmd uses llm-agents.nix overlay instead of dedicated flake input

**Decision**: Replace `self.inputs.qmd.packages.${pkgs.system}.default` with `pkgs.llm-agents.qmd`. Remove the `qmd` flake input.

**Rationale**: llm-agents.nix is the canonical packaging source for both qmd and gno. A separate flake input is redundant.

## Risks / Trade-offs

- **[subcog binary not packaged]** → `${pkgs.subcog}/bin/subcog` doesn't exist. Blocker for subcog deployment. Mitigation: Package in llm-agents.nix before deploying. Other three services can deploy first.
- **[ogham-mcp uvx runtime fetch]** → Not reproducible. Acceptable — uv caches after first fetch.
- **[Hardcoded 10.0.0.1]** → Ties service definitions to bridge topology. Acceptable for single-deployment scenario; can be parameterized later.
- **[agentplot-kit release coordination]** → Moving caddy-cloudflare requires updating agentplot-kit first, then updating downstream flake.locks.
