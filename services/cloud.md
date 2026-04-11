# <service-name>

<!-- One-line description: what the service does, not how it works. -->

<one-line description of what the service does>

**Upstream:** [upstream-org/upstream-repo](https://github.com/upstream-org/upstream-repo)

## Benefits

<!--
  Why a consumer would adopt this clanService rather than configuring
  the upstream tool themselves. Focus on what the consumer gains:
  agent integration, turnkey deployment, multi-instance support, etc.
  2-4 bullets is ideal.
-->

- Benefit one
- Benefit two

## Roles

<!--
  Summary table of all roles this service defines.
  Adapt role names to match the service — not every service uses
  server/client. See "Role variants" notes below.
-->

| Role | Description |
|------|-------------|
| server | One-line summary of the server role |
| client | One-line summary of the client role |

### Server

<!--
  What the server role deploys and configures, in prose.
  Mention key components: systemd service, reverse proxy,
  database backend, authentication, etc.

  CLIENT-ONLY SERVICES: Omit this subsection entirely.
  Add "(client-only)" after the Client heading instead —
  see himalaya for an example.
-->

Deploys ... as a systemd service with ... backend and Caddy reverse proxy.

### Client

<!--
  All client roles use mkClientTooling. List the capabilities
  the client provides in the table below, then note which
  targets are available.
-->

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| Skill | What the skill does |
| CLI | What the CLI wrapper provides |
| MCP | Endpoint type and what it exposes |
| Secret | How secrets are provisioned (prompted / shared) |
| Extra packages | Additional packages installed globally |

<!--
  Only include rows for capabilities the service actually provides.
  Common capability combinations:
    - Skill + CLI + Secret  (linkding, himalaya)
    - Skill + MCP + Secret  (subcog, ogham-mcp, atomic)
    - Skill + Extra packages (openclaw)
-->

**Available targets:** `claude-code.skill`, `claude-code.mcp`, `agent-skills`, `openclaw.skill`, `agent-deck.skill`, `agent-deck.mcp`, `cli`

<!--
  List only the targets this service actually supports.
  If a capability is absent (e.g., no MCP), note it briefly:
  "No MCP server, so MCP targets are not available."
-->

## Example Inventory

<!--
  A realistic Nix code block showing how a deployment inventory
  would consume this service. Include at least one role assignment
  and representative config. For client roles, show multi-client
  usage if the service supports it.
-->

```nix
{
  services.<service-name>.server.<machine> = {
    roles = [ "server" ];
    config = {
      domain = "<service>.example.com";
    };
  };

  services.<service-name>.client.<machine> = {
    roles = [ "client" ];
    config.clients = {
      default = {
        name = "<service-name>";
        domain = "<service>.example.com";
        claude-code.skill.enabled = true;
      };
    };
  };
}
```

## Key Options

<!--
  Document the most important interface options.

  When a service has multiple roles with many options, split into
  subsections by role (### Server, ### Client, etc.) — see openclaw
  for an example. For simpler services, a single table is fine.

  Include the Default column when defaults are meaningful.
  Omit it (as microvm does) when most options have no default.
-->

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clients.<name>.name` | string | attr name | Integration identifier |
| `clients.<name>.domain` | string | — | FQDN of the service instance |
| `clients.<name>.claude-code.skill.enabled` | bool | `true` | Install Claude Code agent skill |

<!--
  ============================================================
  TEMPLATE NOTES — remove everything below in actual READMEs
  ============================================================

  Role variants
  -------------
  Not every service uses server/client. Adapt the Roles table
  to match the service:

    server + client         — linkding, subcog, ogham-mcp, atomic
    server + node + client  — openclaw
    host + guest            — microvm
    client-only             — himalaya, tana, obsidian

  Client-only services
  --------------------
  Omit the Server subsection. Mark the Client heading as
  "### Client (client-only)" and add a note:
  "No server role — <service> connects to external <X> servers."

  Benefits section
  ----------------
  Focus on what the consumer gains, not implementation details.
  Good: "Multi-instance support with per-client auth isolation"
  Bad:  "Uses mkClientTooling to generate interface options"

  Key Options — splitting by role
  -------------------------------
  If a service has many options across roles, use subsections:

    ## Key Options
    ### Server
    | Option | ... |
    ### Client
    | Option | ... |

  See openclaw README for this pattern in practice.
-->
