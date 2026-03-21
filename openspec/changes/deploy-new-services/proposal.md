## Why

Four agentplot services (ogham-mcp, qmd, subcog, gno) are defined as clanServices but have never been deployed to swancloud. Before they can be deployed, several server role issues need fixing: ogham-mcp and subcog incorrectly define their own PostgreSQL instances instead of using the host's shared PostgreSQL via clan inventory (the pattern linkding and paperless use), gno uses an OCI container instead of the bun2nix package available in llm-agents.nix, and the caddy-cloudflare module is duplicated between swancloud and agentplot rather than living in agentplot-kit where all consumers can share it. Client roles have already been refactored to use `mkClientTooling` (extract-client-tooling change) — no client-side code changes are needed in agentplot.

## What Changes

- **Move caddy-cloudflare module to agentplot-kit**: Extract from swancloud, generalize (remove swancloud.net reference), export as `nixosModules.caddy-cloudflare`. Remove copies from both swancloud and agentplot.
- **Fix ogham-mcp server role**: Remove `services.postgresql` definition (database/user/extensions). Remove `postgresHost` option. Hardcode DB host as `10.0.0.1` in the DATABASE_URL (same pattern as linkding's `LD_DB_HOST = "10.0.0.1"`). Keep `uvx ogham-mcp` runtime.
- **Fix subcog server role**: Remove `services.postgresql` definition. Remove `postgresHost` option. Hardcode DB host as `10.0.0.1`. Note: subcog references `${pkgs.subcog}/bin/subcog` — the Rust binary packaging is a prerequisite (not yet in llm-agents.nix or nixpkgs).
- **Fix gno server role**: Replace OCI/Podman container with `pkgs.llm-agents.gno` (bun2nix package from llm-agents.nix overlay). Use a systemd service instead of `virtualisation.oci-containers`.
- **Fix qmd server role**: Replace `self.inputs.qmd.packages` reference with `pkgs.llm-agents.qmd` from llm-agents.nix overlay. Remove the `qmd` flake input from agentplot's `flake.nix`.
- **Add swancloud inventory wiring**: microvm guest entries, coredns DNS records, borgbackup clients, service instances with server role settings, PostgreSQL databases/users on swancloud-srv, machine configurations with static IPs and caddy-cloudflare imports, llm-agents.nix overlay on guests that need it.
- **Add swancloud client roles on darwin**: MCP endpoint configuration for ogham-mcp, qmd, subcog, gno on mac-studio and macbook-pro using the `mkClientTooling`-generated client interfaces.

## Capabilities

### New Capabilities
- `caddy-cloudflare-kit`: Shared caddy-cloudflare NixOS module in agentplot-kit, exported as `nixosModules.caddy-cloudflare`
- `swancloud-service-deployment`: Inventory wiring, machine configs, and PostgreSQL provisioning for ogham/qmd/subcog/gno in swancloud

### Modified Capabilities
- `ogham-server`: Remove PostgreSQL self-provisioning; service assumes external database host at 10.0.0.1
- `subcog-server`: Remove PostgreSQL self-provisioning; service assumes external database host at 10.0.0.1
- `gno-server`: Replace OCI container with bun2nix systemd service using llm-agents.nix package
- `qmd-server`: Replace flake input package reference with llm-agents.nix overlay package

## Impact

- **agentplot-kit** (new module): `modules/caddy-cloudflare.nix`, `flake.nix` exports
- **agentplot** (server role fixes only): `services/ogham-mcp/default.nix`, `services/subcog/default.nix`, `services/gno/default.nix`, `services/qmd/default.nix`, `flake.nix` (remove qmd input), `modules/caddy-cloudflare.nix` (delete). Client roles are unchanged — already refactored via extract-client-tooling.
- **swancloud** (deployment): `clan.nix` (inventory), `machines/` (4 new machine configs), `machines/swancloud-srv/configuration.nix` (PG databases/users/passwords), `modules/caddy-cloudflare.nix` (replace with agentplot-kit import), existing guest configs updated to use agentplot-kit caddy-cloudflare
- Existing linkding and paperless deployments are unaffected
