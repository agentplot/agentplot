## Why

Four agentplot services (ogham-mcp, qmd, subcog, gno) are defined as clanServices but have never been deployed. Before they can be deployed, several server role issues need fixing: ogham-mcp and subcog incorrectly define their own PostgreSQL instances instead of using the host's shared PostgreSQL via clan inventory (the pattern linkding and paperless use), gno uses an OCI container instead of the bun2nix package available in llm-agents.nix, qmd uses a dedicated flake input instead of the llm-agents.nix overlay, and the caddy-cloudflare module is duplicated between repos rather than living in agentplot-kit where all consumers can share it. Client roles have already been refactored to use `mkClientTooling` (extract-client-tooling change) — no client-side code changes are needed.

## What Changes

- **Move caddy-cloudflare module to agentplot-kit**: Extract from swancloud, generalize (remove swancloud.net reference), export as `nixosModules.caddy-cloudflare`. Remove the copy from agentplot.
- **Fix ogham-mcp server role**: Remove `services.postgresql` definition (database/user/extensions). Remove `postgresHost` option. Hardcode DB host as `10.0.0.1` in the DATABASE_URL (same pattern as linkding's `LD_DB_HOST = "10.0.0.1"`). Keep `uvx ogham-mcp` runtime.
- **Fix subcog server role**: Remove `services.postgresql` definition. Remove `postgresHost` option. Hardcode DB host as `10.0.0.1`. Note: subcog references `${pkgs.subcog}/bin/subcog` — the Rust binary packaging is a prerequisite (not yet in llm-agents.nix or nixpkgs).
- **Fix gno server role**: Replace OCI/Podman container with `pkgs.llm-agents.gno` (bun2nix package from llm-agents.nix overlay). Use a systemd service instead of `virtualisation.oci-containers`.
- **Fix qmd server role**: Replace `self.inputs.qmd.packages` reference with `pkgs.llm-agents.qmd` from llm-agents.nix overlay. Remove the `qmd` flake input from agentplot's `flake.nix`.

Swancloud-specific deployment (inventory wiring, machine configs, PostgreSQL provisioning, client roles on darwin) is tracked separately in the swancloud repo's `deploy-agentplot-services` change.

## Capabilities

### New Capabilities
- `caddy-cloudflare-kit`: Shared caddy-cloudflare NixOS module in agentplot-kit, exported as `nixosModules.caddy-cloudflare`

### Modified Capabilities
- `ogham-server`: Remove PostgreSQL self-provisioning; service assumes external database host at 10.0.0.1
- `subcog-server`: Remove PostgreSQL self-provisioning; service assumes external database host at 10.0.0.1
- `gno-server`: Replace OCI container with bun2nix systemd service using llm-agents.nix package
- `qmd-server`: Replace flake input package reference with llm-agents.nix overlay package

## Impact

- **agentplot-kit** (new module): `modules/caddy-cloudflare.nix`, `flake.nix` exports
- **agentplot** (server role fixes only): `services/ogham-mcp/default.nix`, `services/subcog/default.nix`, `services/gno/default.nix`, `services/qmd/default.nix`, `flake.nix` (remove qmd input), `modules/caddy-cloudflare.nix` (delete). Client roles are unchanged.
- Downstream: swancloud change `deploy-agentplot-services` depends on this completing first
