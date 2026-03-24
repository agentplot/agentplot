# miniflux

Minimalist RSS reader with a clean reading experience, full REST API, and feed management. Useful for keeping up with blogs, news, and documentation changes through agent-accessible feed queries.

**Upstream:** [miniflux/v2](https://github.com/miniflux/v2)

## Roles

### Server

Deploys Miniflux via the NixOS `services.miniflux` module with external PostgreSQL and Caddy reverse proxy. Supports optional OIDC authentication via Kanidm.

### Client

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| Skill | CLI-based skill wrapping restish with bundled OpenAPI spec |
| CLI | Per-client `miniflux-cli` wrapper with pre-configured auth |
| Secret | Prompted API token per client |

**Available targets:** `claude-code.skill`, `agent-skills`, `openclaw.skill`, `agent-deck.skill`, `cli`

## Example Inventory

```nix
{
  services.miniflux.server.rss-vm = {
    roles = [ "server" ];
    config.domain = "rss.swancloud.net";
    config.oidc.enable = true;
    config.oidc.issuerDomain = "auth.swancloud.net";
  };

  services.miniflux.client.mac = {
    roles = [ "client" ];
    config.clients = {
      personal = {
        name = "miniflux";
        base_url = "https://rss.swancloud.net";
        claude-code.skill.enabled = true;
        cli.enabled = true;
      };
    };
  };
}
```

## Key Options

### Server

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `domain` | string | — | FQDN for the Miniflux instance |
| `oidc.enable` | bool | `false` | Enable OIDC authentication via Kanidm |
| `oidc.issuerDomain` | string | `""` | Kanidm server domain |

### Client

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clients.<name>.name` | string | attr name | CLI binary name and integration identifier |
| `clients.<name>.base_url` | string | — | Base URL of the Miniflux instance |
| `clients.<name>.cli.enabled` | bool | `true` | Install per-client CLI wrapper |
| `clients.<name>.claude-code.skill.enabled` | bool | `true` | Install Claude Code agent skill |
| `clients.<name>.agent-skills.enabled` | bool | `false` | Distribute skill via agent-skills module |
| `clients.<name>.openclaw.skill.enabled` | bool | `false` | Add OpenClaw skill |
| `clients.<name>.agent-deck.skill.enabled` | bool | `false` | Add skill to agent-deck pool |
