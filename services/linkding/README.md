# linkding

Bookmark manager with full REST API, tag-based organization, bundles (saved searches), and asset attachments.

**Upstream:** [sissbruecker/linkding](https://github.com/sissbruecker/linkding)

## Roles

### Server

Deploys a linkding OCI container with PostgreSQL database and Caddy reverse proxy. Supports optional OIDC authentication via Kanidm.

### Client

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| Skill | CLI-based skill wrapping restish with bundled OpenAPI spec |
| CLI | Per-client `linkding-cli` wrapper with pre-configured auth |
| Secret | Prompted API token per client |

**Available targets:** `claude-code.skill`, `agent-skills`, `openclaw.skill`, `agent-deck.skill`, `cli`

linkding has no MCP server, so MCP targets are not available.

## Example Inventory

```nix
{
  services.linkding.server.swan = {
    roles = [ "server" ];
    config.domain = "links.swancloud.net";
  };

  services.linkding.client.mac = {
    roles = [ "client" ];
    config.clients = {
      personal = {
        name = "linkding";
        base_url = "https://links.swancloud.net";
        claude-code.skill.enabled = true;
        agent-skills.enabled = true;
        cli.enabled = true;
      };
      work = {
        name = "linkding-biz";
        base_url = "https://links.work.example.com";
        default_tags = [ "work" ];
      };
    };
  };
}
```

## Key Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clients.<name>.name` | string | attr name | CLI binary name and integration identifier |
| `clients.<name>.base_url` | string | — | Base URL of the linkding instance |
| `clients.<name>.default_tags` | list of string | `[]` | Default tags for bookmarks |
| `clients.<name>.cli.enabled` | bool | `true` | Install per-client CLI wrapper |
| `clients.<name>.claude-code.skill.enabled` | bool | `true` | Install Claude Code agent skill |
| `clients.<name>.agent-skills.enabled` | bool | `false` | Distribute skill via agent-skills module |
| `clients.<name>.openclaw.skill.enabled` | bool | `false` | Add OpenClaw skill |
| `clients.<name>.agent-deck.skill.enabled` | bool | `false` | Add skill to agent-deck pool |
