## Context

Four agentplot clanServices (ogham-mcp, qmd, subcog, gno) exist but have never been deployed. The deployment target is swancloud, which runs services as microvm guests on `swancloud-srv` with a shared PostgreSQL instance on the host, CoreDNS for internal `*.swancloud.net` resolution, and Caddy with Cloudflare DNS-01 ACME for TLS.

Current issues blocking deployment:
- ogham-mcp and subcog define `services.postgresql` in their server roles — this conflicts with swancloud's pattern where PostgreSQL runs on the host and guests connect over the bridge network
- gno uses an OCI/Podman container — unnecessary since `llm-agents.nix` already packages gno with bun2nix
- qmd references a dedicated `qmd` flake input — should use `pkgs.llm-agents.qmd` from the overlay
- `caddy-cloudflare.nix` is duplicated across repos instead of living in the shared agentplot-kit

## Goals / Non-Goals

**Goals:**
- Deploy ogham-mcp, qmd, subcog, gno as microvm guests on swancloud-srv
- Fix PostgreSQL pattern in ogham-mcp and subcog to match linkding/paperless (host-managed PG)
- Replace gno OCI container with bun2nix systemd service
- Consolidate caddy-cloudflare module in agentplot-kit
- Configure client roles (MCP endpoints) on mac-studio and macbook-pro

**Non-Goals:**
- Refactoring how linkding/paperless hardcode `10.0.0.1` — current pattern works, can improve later
- Adding OIDC/Kanidm authentication to new services (ogham uses API keys, subcog uses JWT, qmd/gno are unauthenticated)
- Changing the microvm networking model (bridge + TAP + CoreDNS)
- Adding new features to any service — this is deployment, not enhancement

## Decisions

### D1: caddy-cloudflare lives in agentplot-kit

**Decision**: Move to `agentplot-kit/modules/caddy-cloudflare.nix`, export as `nixosModules.caddy-cloudflare`.

**Rationale**: Every service with a Caddy server role needs this module. It's infrastructure shared between agentplot service consumers (swancloud, potentially others). agentplot-kit is the framework layer — this fits there. The swancloud-specific text ("for swancloud.net") in the prompt description will be generalized.

**Alternative considered**: Keep in agentplot alongside services. Rejected because agentplot-kit already exports shared modules (HM modules for secretspec, claude-code) and caddy-cloudflare is service-agnostic.

### D2: Remove PostgreSQL from ogham-mcp and subcog server roles

**Decision**: Strip all `services.postgresql` configuration. Services take a `dbHost` string (defaulting to `"10.0.0.1"` would be wrong — we hardcode it in the environment config the same way linkding hardcodes `LD_DB_HOST`). The consuming inventory (swancloud) provisions the database, user, and password on the host.

**Rationale**: The established pattern in swancloud is:
1. Host runs shared PostgreSQL with `clan.core.postgresql` for database/user creation
2. Host mirrors the shared vars generator for the DB password
3. Host runs a oneshot systemd service to `ALTER USER ... PASSWORD` from the shared secret
4. Guest connects to `10.0.0.1:5432` with password from the same shared vars generator
5. Guest never touches `services.postgresql`

ogham-mcp and subcog must follow this exact pattern.

**Alternative considered**: Making `postgresHost` configurable with a conditional `lib.mkIf (postgresHost == "localhost")` to enable local PG. Rejected — this creates two code paths to maintain and doesn't match how any other service works in swancloud.

### D3: gno uses bun2nix package from llm-agents.nix overlay

**Decision**: Replace `virtualisation.oci-containers.containers.gno` with a `systemd.services.gno` running `pkgs.llm-agents.gno`. The package is available via the `llm-agents.nix` overlay already applied on swancloud-srv (and inherited by guests via `nixpkgs.overlays`).

**Rationale**: llm-agents.nix already has a fully working bun2nix build of gno with GPU support, SQLite linking, and NixOS-specific patches. Using the OCI container means maintaining a separate runtime and losing Nix reproducibility.

**Collection bind-mounts**: Instead of container volume mounts, gno runs natively and accesses collection paths directly via the filesystem (virtiofs shares from host or local `/persist` paths).

### D4: qmd uses llm-agents.nix overlay instead of dedicated flake input

**Decision**: Replace `self.inputs.qmd.packages.${pkgs.system}.default` with `pkgs.llm-agents.qmd`. Remove the `qmd` flake input from agentplot's `flake.nix`.

**Rationale**: Same as gno — llm-agents.nix is the canonical packaging source for both, and the overlay is already applied in swancloud. Having a separate flake input is redundant.

**Note**: agentplot's `flake.nix` currently lists `qmd` as an input. This gets removed. The swancloud machines that need qmd/gno packages get them via the `llm-agents.nix` overlay, which swancloud already applies.

### D5: IP allocation for new guests

**Decision**: Assign sequential IPs continuing from the existing allocation:
- `10.0.0.7` — ogham
- `10.0.0.8` — subcog
- `10.0.0.9` — qmd
- `10.0.0.12` — gno

(10.0.0.10 and 10.0.0.11 are taken by agent-dev-business and agent-dev-willdan)

### D6: Database host address hardcoded in service roles

**Decision**: Each service's server role hardcodes the database host address in its environment configuration, matching the linkding/paperless pattern. For ogham-mcp: `DATABASE_URL=postgresql://ogham:$PASSWORD@10.0.0.1/ogham`. For subcog: `SUBCOG_DATABASE_URL=postgresql://subcog@10.0.0.1/subcog`.

**Rationale**: This matches the established pattern. linkding hardcodes `LD_DB_HOST = "10.0.0.1"`, paperless hardcodes `PAPERLESS_DBHOST = "10.0.0.1"`. While this couples the service definition to the network topology, it's consistent and works for a single-deployment scenario.

## Risks / Trade-offs

- **[pgvector extension on host]** → swancloud-srv already has `postgresql_17.withPackages (ps: [ps.pgvector])`. ogham and subcog need pgvector — this is already satisfied. No action needed.
- **[Overlay availability in guests]** → Guests need `pkgs.llm-agents.qmd` and `pkgs.llm-agents.gno`. The overlay is applied on swancloud-srv but guests may not inherit it automatically. Mitigation: Apply the overlay in guest machine configs or in clan.nix machine-level config.
- **[Hardcoded 10.0.0.1]** → Ties service definitions to swancloud's bridge topology. Acceptable for now; if agentplot services need to be reusable across different deployments, this can be parameterized later.
- **[agentplot-kit release coordination]** → Moving caddy-cloudflare to agentplot-kit requires updating agentplot-kit, then updating agentplot and swancloud's flake.lock to pick up the new version. Three-repo coordination.
