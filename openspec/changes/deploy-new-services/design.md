## Context

Four agentplot clanServices (ogham-mcp, qmd, subcog, gno) exist but have never been deployed. The deployment target is swancloud, which runs services as microvm guests on `swancloud-srv` with a shared PostgreSQL instance on the host, CoreDNS for internal `*.swancloud.net` resolution, and Caddy with Cloudflare DNS-01 ACME for TLS.

Client roles have already been refactored to use `mkClientTooling` from agentplot-kit (extract-client-tooling change). Only server roles and swancloud inventory wiring need work.

Current issues blocking deployment:
- ogham-mcp and subcog define `services.postgresql` in their server roles — this conflicts with swancloud's pattern where PostgreSQL runs on the host and guests connect over the bridge network
- gno uses an OCI/Podman container — unnecessary since `llm-agents.nix` already packages gno with bun2nix
- qmd references a dedicated `qmd` flake input — should use `pkgs.llm-agents.qmd` from the overlay
- subcog references `${pkgs.subcog}/bin/subcog` but this package doesn't exist in any overlay or nixpkgs — needs packaging
- ogham-mcp uses `uvx ogham-mcp` (fetches from PyPI at runtime) — this works but is not reproducible; acceptable for now
- `caddy-cloudflare.nix` is duplicated across repos instead of living in the shared agentplot-kit

## Goals / Non-Goals

**Goals:**
- Deploy ogham-mcp, qmd, subcog, gno as microvm guests on swancloud-srv
- Fix PostgreSQL pattern in ogham-mcp and subcog to match linkding/paperless (host-managed PG)
- Replace gno OCI container with bun2nix systemd service
- Consolidate caddy-cloudflare module in agentplot-kit
- Configure client roles (MCP endpoints) on mac-studio and macbook-pro via inventory

**Non-Goals:**
- Refactoring client roles — already done via extract-client-tooling
- Refactoring how linkding/paperless hardcode `10.0.0.1` — current pattern works, can improve later
- Adding OIDC/Kanidm authentication to new services (ogham uses API keys, subcog uses JWT, qmd/gno are unauthenticated)
- Changing the microvm networking model (bridge + TAP + CoreDNS)
- Packaging subcog as a Nix derivation (prerequisite, tracked separately)
- Making ogham-mcp reproducible (currently uses `uvx` for runtime fetch)

## Decisions

### D1: caddy-cloudflare lives in agentplot-kit

**Decision**: Move to `agentplot-kit/modules/caddy-cloudflare.nix`, export as `nixosModules.caddy-cloudflare`.

**Rationale**: Every service with a Caddy server role needs this module. It's infrastructure shared between agentplot service consumers (swancloud, potentially others). agentplot-kit is the framework layer — this fits there. The swancloud-specific text ("for swancloud.net") in the prompt description will be generalized.

**Alternative considered**: Keep in agentplot alongside services. Rejected because agentplot-kit already exports shared modules (HM modules for secretspec, claude-code, mkClientTooling) and caddy-cloudflare is service-agnostic.

### D2: Remove PostgreSQL from ogham-mcp and subcog server roles

**Decision**: Strip all `services.postgresql` configuration. Hardcode `10.0.0.1` as the database host in the environment config, matching how linkding hardcodes `LD_DB_HOST = "10.0.0.1"`. The consuming inventory (swancloud) provisions the database, user, and password on the host.

**Rationale**: The established pattern in swancloud is:
1. Host runs shared PostgreSQL with `clan.core.postgresql` for database/user creation
2. Host mirrors the shared vars generator for the DB password
3. Host runs a oneshot systemd service to `ALTER USER ... PASSWORD` from the shared secret
4. Guest connects to `10.0.0.1:5432` with password from the same shared vars generator
5. Guest never touches `services.postgresql`

ogham-mcp and subcog must follow this exact pattern.

**Alternative considered**: Making `postgresHost` configurable with a conditional `lib.mkIf (postgresHost == "localhost")` to enable local PG. Rejected — this creates two code paths to maintain and doesn't match how any other service works in swancloud.

### D3: gno uses bun2nix package from llm-agents.nix overlay

**Decision**: Replace `virtualisation.oci-containers.containers.gno` with a `systemd.services.gno` running `pkgs.llm-agents.gno`. The package is available via the `llm-agents.nix` overlay applied in guest machine configs.

**Rationale**: llm-agents.nix already has a fully working bun2nix build of gno with GPU support, SQLite linking, and NixOS-specific patches (detectGlibc, fastify-send UTF-8 fix). Using the OCI container means maintaining a separate runtime and losing Nix reproducibility.

**Collection paths**: Instead of container volume mounts, gno runs natively and accesses collection paths directly via the filesystem (virtiofs shares from host or local `/persist` paths). The config file generation stays the same but paths map directly instead of through container mounts.

### D4: qmd uses llm-agents.nix overlay instead of dedicated flake input

**Decision**: Replace `self.inputs.qmd.packages.${pkgs.system}.default` with `pkgs.llm-agents.qmd`. Remove the `qmd` flake input from agentplot's `flake.nix`.

**Rationale**: llm-agents.nix is the canonical packaging source for both qmd and gno, and the overlay is already applied in swancloud. Having a separate flake input is redundant.

### D5: IP allocation for new guests

**Decision**: Assign sequential IPs continuing from the existing allocation:
- `10.0.0.7` — ogham
- `10.0.0.8` — subcog
- `10.0.0.9` — qmd
- `10.0.0.12` — gno

(10.0.0.10 and 10.0.0.11 are taken by agent-dev-business and agent-dev-willdan)

### D6: Database host address hardcoded in service roles

**Decision**: Each service's server role hardcodes `10.0.0.1` as the database host in its environment configuration, matching the linkding/paperless pattern. For ogham-mcp: `DATABASE_URL=postgresql://ogham:$PASSWORD@10.0.0.1/ogham`. For subcog: `SUBCOG_DATABASE_URL=postgresql://subcog@10.0.0.1/subcog`.

**Rationale**: linkding hardcodes `LD_DB_HOST = "10.0.0.1"`, paperless hardcodes `PAPERLESS_DBHOST = "10.0.0.1"`. Consistent and works for a single-deployment scenario.

### D7: Client roles use mkClientTooling — no changes needed

**Decision**: Client roles were refactored to `mkClientTooling` in the extract-client-tooling change. The swancloud inventory wires client settings through the generated interface. No code changes needed in agentplot service definitions for client roles.

The client settings in swancloud inventory will use the `mkClientTooling`-generated option structure: ogham-mcp clients have `url` (SSE endpoint), qmd/gno/subcog clients have `domain` (FQDN).

## Risks / Trade-offs

- **[subcog binary not packaged]** → `${pkgs.subcog}/bin/subcog` doesn't exist in any overlay or nixpkgs. Subcog is a Rust binary. This is a blocker for subcog deployment. Mitigation: Package subcog in llm-agents.nix (buildRustPackage or crane) before deploying. Can deploy the other three services first.
- **[ogham-mcp uvx runtime fetch]** → `uvx ogham-mcp` fetches from PyPI on first start, not reproducible. Acceptable for now — uv caches after first fetch, and ogham-mcp is a rapidly evolving Python package.
- **[pgvector extension on host]** → swancloud-srv already has `postgresql_17.withPackages (ps: [ps.pgvector])`. ogham and subcog need pgvector — already satisfied.
- **[Overlay availability in guests]** → Guests need `pkgs.llm-agents.qmd` and `pkgs.llm-agents.gno`. Mitigation: Apply `inputs.llm-agents.overlays.default` in guest machine configs.
- **[Hardcoded 10.0.0.1]** → Ties service definitions to swancloud's bridge topology. Acceptable for now; can be parameterized later if needed.
- **[agentplot-kit release coordination]** → Moving caddy-cloudflare to agentplot-kit requires updating agentplot-kit, then updating agentplot and swancloud's flake.lock. Three-repo coordination.
