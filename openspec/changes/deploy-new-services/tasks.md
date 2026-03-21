## 1. caddy-cloudflare → agentplot-kit

- [ ] 1.1 Create `modules/caddy-cloudflare.nix` in agentplot-kit, generalized from swancloud's version (remove "for swancloud.net" from prompt description)
- [ ] 1.2 Add `nixosModules.caddy-cloudflare = import ./modules/caddy-cloudflare.nix` to agentplot-kit's `flake.nix` outputs
- [ ] 1.3 Delete `modules/caddy-cloudflare.nix` from agentplot repo

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

## 4. Verification

- [ ] 4.1 Verify agentplot `nix flake check` passes (no qmd input, no caddy-cloudflare module)
- [ ] 4.2 Verify agentplot-kit `nix flake check` passes with new caddy-cloudflare export
