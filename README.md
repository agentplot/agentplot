# AgentPlot

Agent-optimized [clanServices](https://docs.clan.lol/) — co-located infrastructure, CLI packages, skills, and Home Manager module delegation, all built on Nix flakes.

## The Problem

Deploying a self-hosted service typically means configuring the server, then separately setting up CLI tools, AI agent skills, and MCP servers on your dev machine — all maintained in different places, falling out of sync.

## The Solution

AgentPlot bundles everything a service needs into a single **clanService**:

```
services/linkding/
├── default.nix          # Server infra + client tooling in one declaration
├── packages/
│   └── linkding-cli/    # CLI wrapper (auto-discovers API endpoints)
└── skills/
    └── SKILL.md         # AI agent skill (Claude, etc.)
```

Each service defines **roles** — server, client, host, guest, or whatever the service needs. A role encapsulates the NixOS/Darwin modules, packages, skills, and configuration for that aspect of the service.

## How It Works

### Declare a Service

A clanService defines its roles, interfaces, and per-instance configuration:

```nix
# services/linkding/default.nix
{
  _class = "clan.service";
  manifest.name = "linkding";

  roles.server = {
    # NixOS module: OCI container, PostgreSQL, Caddy reverse proxy
  };

  roles.client = {
    interface = { lib, ... }: {
      options.clients = lib.mkOption {
        # Named client configs: CLI name, base URL, default tags, MCP/skill toggles
      };
    };
    perInstance = { settings, ... }: {
      # For each client: CLI wrapper, agent skill, MCP config, HM module
    };
  };
}
```

### Consume in Your Fleet

Add AgentPlot to your Clan fleet and assign roles to machines via inventory:

```nix
# In your fleet's flake.nix
{
  inputs.agentplot.url = "github:agentplot/agentplot";
}
```

```nix
# In your fleet's inventory
{
  services.linkding.instance1 = {
    roles.server.machines.webserver = {
      domain = "links.example.com";
      oidc.enable = true;
    };
    roles.client.machines.macbook = {
      clients.personal = {
        name = "linkding";
        base_url = "https://links.example.com";
        claude-code.skill.enabled = true;
        claude-code.mcp.enabled = true;
      };
    };
  };
}
```

### HM Module Delegation

Client roles produce Home Manager modules that accumulate through `agentplot.hmModules`. The adapter module wires them all into a single user's config:

```nix
# In your NixOS/nix-darwin config
{
  imports = [ agentplot.darwinModules.agentplot ];  # or nixosModules

  agentplot.user = "alice";
  # All service HM modules are now wired into home-manager.users.alice
}
```

Multiple services compose without conflict — each client gets its own namespace (e.g., `linkding-personal`, `paperless-default`).

## Services

### linkding

Bookmark manager with full agent tooling.

**Server role**: OCI container (Podman), PostgreSQL, Caddy with automatic TLS (Cloudflare DNS-01), optional OIDC via Kanidm.

**Client role**: Per-client CLI wrappers, Claude Code skills, MCP server configs. Each client gets its own binary name, API token (via `clan.core.vars`), and toggles for which integrations to enable.

The CLI wraps [restish](https://rest.sh/) with a bundled OpenAPI spec — all API endpoints are auto-discovered as typed commands. New API features work immediately without updating the CLI or skills.

### microvm

Run Clan machines as MicroVM guests using cloud-hypervisor.

**Host role**: Imports the microvm host module, creates persistent storage, wires up journal forwarding, manages VM autostart.

**Guest role**: Configures cloud-hypervisor with deterministic vsock CID and MAC (derived from hostname), virtiofs shares for nix store, secrets, SSH, journal, and persistent storage.

## Shared Modules

- **`agentplot`** — HM module delegation adapter. Accumulates `agentplot.hmModules` from all services and wires them into `home-manager.users.<user>`. Available as both `nixosModules.agentplot` and `darwinModules.agentplot`.

- **`caddy-cloudflare`** — Shared Caddy configuration with Cloudflare DNS-01 ACME. Builds Caddy with the cloudflare plugin, manages the API token via `clan.core.vars`, and exposes a `caddy-cloudflare.tls` option for service modules to reference.

## Flake Outputs

| Output | Description |
|--------|-------------|
| `clan.modules.linkding` | linkding clanService |
| `clan.modules.microvm` | microvm clanService |
| `nixosModules.agentplot` | HM delegation adapter (NixOS) |
| `darwinModules.agentplot` | HM delegation adapter (nix-darwin) |
| `packages.<system>.linkding-cli` | Standalone linkding CLI |

## Development

```bash
# Build a package
nix build .#linkding-cli

# Check the flake
nix flake check

# Run the HM module composition smoke test
nix-instantiate --eval tests/hmModules-composition.nix
```

## Supported Systems

`x86_64-linux` · `aarch64-linux` · `aarch64-darwin` · `x86_64-darwin`
