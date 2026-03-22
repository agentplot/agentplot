## 1. caddy-cloudflare → agentplot-kit

- [x] 1.1 Create `modules/caddy-cloudflare.nix` in agentplot-kit, generalized from swancloud's version (remove "for swancloud.net" from prompt description)
- [x] 1.2 Add `nixosModules.caddy-cloudflare = import ./modules/caddy-cloudflare.nix` to agentplot-kit's `flake.nix` outputs
- [x] 1.3 Delete `modules/caddy-cloudflare.nix` from agentplot repo

## 2. Fix agentplot server roles

- [x] 2.1 ogham-mcp: remove `services.postgresql` block (enable, extensions, ensureDatabases, ensureUsers)
- [x] 2.2 ogham-mcp: remove `postgresHost` interface option; hardcode DB host as `10.0.0.1` in the DATABASE_URL environment variable
- [x] 2.3 ogham-mcp: remove `postgresql.service` from systemd `after` and `requires`
- [x] 2.4 ogham-mcp: update `clan.core.state` to only include `/persist/ogham-mcp` (remove `/var/lib/postgresql`)
- [x] 2.5 subcog: remove `services.postgresql` block (enable, extensions, ensureDatabases, ensureUsers)
- [x] 2.6 subcog: remove `postgresHost` interface option; hardcode DB host as `10.0.0.1` in SUBCOG_DATABASE_URL
- [x] 2.7 subcog: remove `postgresql.service` from systemd `after` and `requires`
- [x] 2.8 subcog: remove `pg_dump` pre-hook from borgbackup, use simple path-based backup for `/persist/subcog`
- [x] 2.9 gno: replace `virtualisation.oci-containers` with `systemd.services.gno` using `pkgs.llm-agents.gno`
- [x] 2.10 gno: update collection handling — pass paths directly to gno config instead of container bind-mounts
- [x] 2.11 gno: write gno config file to filesystem directly (no container mount)
- [x] 2.12 qmd: replace `self.inputs.qmd.packages.${pkgs.system}.default` with `pkgs.llm-agents.qmd`
- [x] 2.13 Remove `qmd` flake input from agentplot's `flake.nix`

## 3. Prerequisite: subcog packaging

- [ ] 3.1 Package subcog Rust binary in llm-agents.nix (buildRustPackage or crane) — **BLOCKED**: being handled in llm-agents.nix repo (github:afterthought/llm-agents.nix, branch: add-subcog)
- [ ] 3.2 Verify `pkgs.llm-agents.subcog` is available via overlay after packaging — **BLOCKED**: depends on 3.1

## 4. Verification

- [x] 4.1 Verify agentplot `nix flake check` passes (no qmd input, no caddy-cloudflare module)
- [x] 4.2 Verify agentplot-kit `nix flake check` passes with new caddy-cloudflare export
