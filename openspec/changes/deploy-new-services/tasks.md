## 1. caddy-cloudflare → agentplot-kit

- [ ] 1.1 Create `modules/caddy-cloudflare.nix` in agentplot-kit, generalized from swancloud's version (remove "for swancloud.net" from prompt description)
- [ ] 1.2 Add `nixosModules.caddy-cloudflare = import ./modules/caddy-cloudflare.nix` to agentplot-kit's `flake.nix` outputs
- [ ] 1.3 Delete `modules/caddy-cloudflare.nix` from agentplot repo
- [ ] 1.4 Delete `modules/caddy-cloudflare.nix` from swancloud repo

## 2. Fix agentplot service definitions

- [ ] 2.1 ogham-mcp server role: remove `services.postgresql` block (enable, extensions, ensureDatabases, ensureUsers)
- [ ] 2.2 ogham-mcp server role: remove `postgresHost` interface option; hardcode DB host as `10.0.0.1` in the DATABASE_URL environment variable (matching linkding/paperless pattern)
- [ ] 2.3 ogham-mcp server role: remove `postgresql.service` from systemd `after` and `requires` (no local PG)
- [ ] 2.4 ogham-mcp server role: update borgbackup state to only include `/persist/ogham-mcp` (not postgresql data dir)
- [ ] 2.5 subcog server role: remove `services.postgresql` block (enable, extensions, ensureDatabases, ensureUsers)
- [ ] 2.6 subcog server role: remove `postgresHost` interface option; hardcode DB host as `10.0.0.1` in SUBCOG_DATABASE_URL
- [ ] 2.7 subcog server role: remove `postgresql.service` from systemd `after` and `requires`
- [ ] 2.8 subcog server role: update borgbackup to only include `/persist/subcog` (remove pg_dump pre-hook)
- [ ] 2.9 gno server role: replace `virtualisation.oci-containers` with `systemd.services.gno` using `pkgs.llm-agents.gno`
- [ ] 2.10 gno server role: update collection handling to use direct filesystem paths instead of container bind-mounts
- [ ] 2.11 gno server role: write gno config file to filesystem instead of container mount
- [ ] 2.12 qmd server role: replace `self.inputs.qmd.packages.${pkgs.system}.default` with `pkgs.llm-agents.qmd`
- [ ] 2.13 Remove `qmd` flake input from agentplot's `flake.nix`

## 3. swancloud inventory wiring

- [ ] 3.1 Add machine entries for ogham, qmd, subcog, gno to `inventory.machines` with tags `["nixos" "microvm"]`
- [ ] 3.2 Add microvm guest entries for all four machines with `settings.host = "swancloud-srv"`
- [ ] 3.3 Add CoreDNS entries: ogham (10.0.0.7, services: ["ogham-mcp"]), subcog (10.0.0.8, services: ["subcog"]), qmd (10.0.0.9, services: ["qmd"]), gno (10.0.0.12, services: ["gno"])
- [ ] 3.4 Add borgbackup client entries for ogham, qmd, subcog, gno
- [ ] 3.5 Add ogham-mcp service instance: `module.input = "agentplot"`, `module.name = "ogham-mcp"`, server on ogham machine with `domain = "ogham.swancloud.net"`
- [ ] 3.6 Add subcog service instance: `module.input = "agentplot"`, `module.name = "subcog"`, server on subcog machine with `domain = "subcog.swancloud.net"`
- [ ] 3.7 Add qmd service instance: `module.input = "agentplot"`, `module.name = "qmd"`, server on qmd machine with `domain = "qmd.swancloud.net"`
- [ ] 3.8 Add gno service instance: `module.input = "agentplot"`, `module.name = "gno"`, server on gno machine with `domain = "gno.swancloud.net"`
- [ ] 3.9 Add client roles for ogham-mcp, qmd, subcog, gno on mac-studio and macbook-pro

## 4. swancloud host configuration (swancloud-srv)

- [ ] 4.1 Add `clan.core.postgresql.databases.ogham` and `clan.core.postgresql.users.ogham` with owner and restore config
- [ ] 4.2 Add `clan.core.postgresql.databases.subcog` and `clan.core.postgresql.users.subcog` with owner and restore config
- [ ] 4.3 Add shared vars generators for ogham-db-password and subcog-db-password (mirror pattern from linkding/paperless)
- [ ] 4.4 Add oneshot systemd services to set ogham and subcog PostgreSQL user passwords from shared secrets
- [ ] 4.5 Update swancloud-srv imports: replace `./modules/caddy-cloudflare.nix` with `inputs.agentplot-kit.nixosModules.caddy-cloudflare`

## 5. swancloud guest machine configurations

- [ ] 5.1 Create `machines/ogham/configuration.nix`: import caddy-cloudflare from agentplot-kit, hostPlatform x86_64-linux, hostName "ogham", static IP 10.0.0.7/24, llm-agents overlay
- [ ] 5.2 Create `machines/subcog/configuration.nix`: import caddy-cloudflare from agentplot-kit, hostPlatform x86_64-linux, hostName "subcog", static IP 10.0.0.8/24
- [ ] 5.3 Create `machines/qmd/configuration.nix`: import caddy-cloudflare from agentplot-kit, hostPlatform x86_64-linux, hostName "qmd", static IP 10.0.0.9/24, llm-agents overlay
- [ ] 5.4 Create `machines/gno/configuration.nix`: import caddy-cloudflare from agentplot-kit, hostPlatform x86_64-linux, hostName "gno", static IP 10.0.0.12/24, llm-agents overlay
- [ ] 5.5 Update existing guest machine configs (linkding, paperless, etc.) to import caddy-cloudflare from agentplot-kit instead of local path

## 6. Verification

- [ ] 6.1 Verify agentplot `nix flake check` passes (no qmd input reference, no caddy-cloudflare module)
- [ ] 6.2 Verify swancloud `nix flake check` passes with new inventory entries and machine configs
- [ ] 6.3 Verify `clan vars generate` prompts for new secrets (ogham-db-password, subcog-db-password, ogham embedding API key, subcog JWT secret, cloudflare-dns-token on new guests)
