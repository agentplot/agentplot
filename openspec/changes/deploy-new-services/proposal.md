## Why

Four agentplot services (ogham-mcp, qmd, subcog, gno) are defined as clanServices but have never been deployed to swancloud. Before they can be deployed, several issues need fixing: ogham-mcp and subcog incorrectly define their own PostgreSQL instances instead of using the host's shared PostgreSQL via clan inventory (the pattern linkding and paperless use), gno uses an OCI container instead of the bun2nix package available in llm-agents.nix, and the caddy-cloudflare module is duplicated between swancloud and agentplot rather than living in agentplot-kit where all consumers can share it.

## What Changes

- **Move caddy-cloudflare module to agentplot-kit**: Extract from swancloud, generalize (remove swancloud.net reference), export as `nixosModules.caddy-cloudflare`. Remove copies from both swancloud and agentplot.
- **Fix ogham-mcp server role**: Remove `services.postgresql` definition (database/user/extensions). Remove `postgresHost` option. The service connects to a host-provided PostgreSQL, with the DB host address hardcoded in the environment config (same pattern as linkding's `LD_DB_HOST = "10.0.0.1"`).
- **Fix subcog server role**: Same as ogham — remove `services.postgresql` definition. Remove `postgresHost` option. Connect to host PostgreSQL.
- **Fix gno server role**: Replace OCI/Podman container with bun2nix-built `pkgs.llm-agents.gno` package from llm-agents.nix overlay. Use a systemd service instead of `virtualisation.oci-containers`.
- **Fix qmd server role**: Replace `self.inputs.qmd.packages` reference with `pkgs.llm-agents.qmd` from llm-agents.nix overlay. Remove the `qmd` flake input from agentplot's `flake.nix`.
- **Add swancloud inventory wiring**: microvm guest entries, coredns DNS records, borgbackup clients, service instances, PostgreSQL databases/users on swancloud-srv, machine configurations with static IPs and caddy-cloudflare imports.
- **Add swancloud client roles on darwin**: MCP endpoint configuration for ogham, qmd, subcog, gno on mac-studio and macbook-pro.

## Capabilities

### New Capabilities
- `caddy-cloudflare-kit`: Shared caddy-cloudflare NixOS module in agentplot-kit, exported as `nixosModules.caddy-cloudflare`
- `swancloud-service-deployment`: Inventory wiring, machine configs, and PostgreSQL provisioning for ogham/qmd/subcog/gno in swancloud

### Modified Capabilities
- `ogham-server`: Remove PostgreSQL self-provisioning; service assumes external database host
- `subcog-server`: Remove PostgreSQL self-provisioning; service assumes external database host
- `gno-server`: Replace OCI container with bun2nix systemd service using llm-agents.nix package
- `qmd-server`: Replace flake input package reference with llm-agents.nix overlay package

## Impact

- **agentplot-kit** (new module): `modules/caddy-cloudflare.nix`, `flake.nix` exports
- **agentplot** (service fixes): `services/ogham-mcp/default.nix`, `services/subcog/default.nix`, `services/gno/default.nix`, `services/qmd/default.nix`, `flake.nix` (remove qmd input), `modules/caddy-cloudflare.nix` (delete)
- **swancloud** (deployment): `clan.nix` (inventory), `machines/` (4 new machine configs), `machines/swancloud-srv/configuration.nix` (PG databases/users/passwords), `modules/caddy-cloudflare.nix` (replace with agentplot-kit import)
- Existing linkding and paperless deployments are unaffected
