## 1. caddy-cloudflare → agentplot-kit

- [ ] 1.1 Create `modules/caddy-cloudflare.nix` in agentplot-kit, generalized from swancloud's version (remove "for swancloud.net" from prompt description)
- [ ] 1.2 Add `nixosModules.caddy-cloudflare = import ./modules/caddy-cloudflare.nix` to agentplot-kit's `flake.nix` outputs
- [ ] 1.3 Delete `modules/caddy-cloudflare.nix` from agentplot repo
- [ ] 1.4 Delete `modules/caddy-cloudflare.nix` from swancloud repo

## 2. Fix agentplot server roles

- [ ] 2.1 ogham-mcp: remove `services.postgresql` block (enable, extensions, ensureDatabases, ensureUsers)
- [ ] 2.2 ogham-mcp: remove `postgresHost` interface option; hardcode DB host as `10.0.0.1` in the DATABASE_URL environment variable
- [ ] 2.3 ogham-mcp: remove `postgresql.service` from systemd `after` and `requires`
- [ ] 2.4 ogham-mcp: update `clan.core.state` to only include `/persist/ogham-mcp` (remove `/var/lib/postgresql`)
- [ ] 2.5 subcog: remove `services.postgresql` block (enable, extensions, ensureDatabases, ensureUsers)
- [ ] 2.6 subcog: remove `postgresHost` interface option; hardcode DB host as `10.0.0.1` in SUBCOG_DATABASE_URL
- [ ] 2.7 subcog: remove `postgresql.service` from systemd `after` and `requires`
- [ ] 2.8 subcog: remove `pg_dump` pre-hook from borgbackup, use simple path-based backup for `/persist/subcog`
- [ ] 2.9 gno: replace `virtualisation.oci-containers` with `systemd.services.gno` using `pkgs.llm-agents.gno`
- [ ] 2.10 gno: update collection handling — pass paths directly to gno config instead of container bind-mounts
- [ ] 2.11 gno: write gno config file to filesystem directly (no container mount)
- [ ] 2.12 qmd: replace `self.inputs.qmd.packages.${pkgs.system}.default` with `pkgs.llm-agents.qmd`
- [ ] 2.13 Remove `qmd` flake input from agentplot's `flake.nix`

## 3. Prerequisite: subcog packaging

- [ ] 3.1 Package subcog Rust binary in llm-agents.nix (buildRustPackage or crane) — `${pkgs.subcog}/bin/subcog` currently doesn't exist in any overlay
- [ ] 3.2 Verify `pkgs.llm-agents.subcog` is available via overlay after packaging

## 4. swancloud inventory wiring

- [ ] 4.1 Add machine entries for ogham, qmd, subcog, gno to `inventory.machines` with tags `["nixos" "microvm"]`
- [ ] 4.2 Add microvm guest entries for all four machines with `settings.host = "swancloud-srv"`
- [ ] 4.3 Add CoreDNS entries: ogham (10.0.0.7, services: ["ogham-mcp"]), subcog (10.0.0.8, services: ["subcog"]), qmd (10.0.0.9, services: ["qmd"]), gno (10.0.0.12, services: ["gno"])
- [ ] 4.4 Add borgbackup client entries for ogham, qmd, subcog, gno
- [ ] 4.5 Add ogham-mcp service instance: `module.input = "agentplot"`, `module.name = "ogham-mcp"`, server on ogham with `domain = "ogham.swancloud.net"` and embedding provider settings
- [ ] 4.6 Add subcog service instance: `module.input = "agentplot"`, `module.name = "subcog"`, server on subcog with `domain = "subcog.swancloud.net"`
- [ ] 4.7 Add qmd service instance: `module.input = "agentplot"`, `module.name = "qmd"`, server on qmd with `domain = "qmd.swancloud.net"` and collection settings
- [ ] 4.8 Add gno service instance: `module.input = "agentplot"`, `module.name = "gno"`, server on gno with `domain = "gno.swancloud.net"` and collection settings
- [ ] 4.9 Add client roles on mac-studio and macbook-pro: ogham-mcp (url-based via mkClientTooling), qmd (domain-based), subcog (domain-based), gno (domain-based)

## 5. swancloud host configuration (swancloud-srv)

- [ ] 5.1 Add `clan.core.postgresql.databases.ogham` and `clan.core.postgresql.users.ogham` with owner and restore config
- [ ] 5.2 Add `clan.core.postgresql.databases.subcog` and `clan.core.postgresql.users.subcog` with owner and restore config
- [ ] 5.3 Add shared vars generators for ogham-db-password and subcog-db-password (mirror pattern from linkding/paperless)
- [ ] 5.4 Add oneshot systemd services to set ogham and subcog PostgreSQL user passwords from shared secrets
- [ ] 5.5 Update swancloud-srv imports: replace `./modules/caddy-cloudflare.nix` with `inputs.agentplot-kit.nixosModules.caddy-cloudflare`

## 6. swancloud guest machine configurations

- [ ] 6.1 Create `machines/ogham/configuration.nix`: import caddy-cloudflare from agentplot-kit, hostPlatform x86_64-linux, hostName "ogham", static IP 10.0.0.7/24
- [ ] 6.2 Create `machines/subcog/configuration.nix`: import caddy-cloudflare from agentplot-kit, hostPlatform x86_64-linux, hostName "subcog", static IP 10.0.0.8/24
- [ ] 6.3 Create `machines/qmd/configuration.nix`: import caddy-cloudflare from agentplot-kit, hostPlatform x86_64-linux, hostName "qmd", static IP 10.0.0.9/24, llm-agents overlay
- [ ] 6.4 Create `machines/gno/configuration.nix`: import caddy-cloudflare from agentplot-kit, hostPlatform x86_64-linux, hostName "gno", static IP 10.0.0.12/24, llm-agents overlay
- [ ] 6.5 Update existing guest machine configs (linkding, paperless, kanidm, openclaw, coredns) to import caddy-cloudflare from agentplot-kit instead of local path

## 7. Verification

- [ ] 7.1 Verify agentplot `nix flake check` passes (no qmd input, no caddy-cloudflare module)
- [ ] 7.2 Verify swancloud `nix flake check` passes with new inventory entries and machine configs
- [ ] 7.3 Verify `clan vars generate` prompts for new secrets (ogham-db-password, subcog-db-password, ogham embedding API key, subcog JWT secret, cloudflare-dns-token on new guests)
