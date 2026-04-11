# paperless

Document management system with OCR, full-text search, mail rule automation, and agent-accessible REST API. Includes Evernote migration tooling.

**Upstream:** [paperless-ngx](https://github.com/paperless-ngx/paperless-ngx)

## Benefits

- **OCR-powered document management** — automatic text recognition, full-text search, and tag-based organization for all ingested documents
- **Agent-driven document search and filing** — REST API skills let coding agents query, tag, and file documents without manual intervention
- **OIDC single sign-on** — optional Kanidm integration for unified authentication across services
- **Evernote migration support** — bundled enex2paperless converter for migrating existing Evernote notebooks into Paperless

## Roles

| Role | Description |
|------|-------------|
| server | NixOS paperless-ngx service with PostgreSQL, Caddy, and OIDC |
| client | Agent tooling: CLI wrappers, skills, and API token management |

### Server

Deploys Paperless-ngx via the NixOS module with external PostgreSQL, Tika OCR, Caddy reverse proxy, optional Kanidm OIDC, and borgbackup state. Secrets (db password, admin password, secret key) are auto-generated via clan vars.

### Client

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| Skills | Paperless API skill + Evernote conversion skill |
| CLI | Per-client `paperless-cli` wrapper (restish, fetches live OpenAPI from instance) |
| Secret | Prompted API token per client |
| Extra packages | enex2paperless (Evernote .enex converter) |

**Available targets:** `claude-code.skill`, `agent-skills`, `openclaw.skill`, `agent-deck.skill`, `cli`

## Example Inventory

```nix
{
  services.paperless.server.docs-vm = {
    roles = [ "server" ];
    config = {
      domain = "docs.swancloud.net";
      oidc.enable = true;
      oidc.issuerDomain = "auth.swancloud.net";
    };
  };

  services.paperless.client.mac = {
    roles = [ "client" ];
    config.clients = {
      personal = {
        name = "paperless";
        base_url = "https://docs.swancloud.net";
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
| `domain` | string | — | FQDN for the Paperless-ngx instance |
| `oidc.enable` | bool | `false` | Enable OIDC authentication via Kanidm |
| `oidc.issuerDomain` | string | `""` | Kanidm server domain |

### Client

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clients.<name>.name` | string | attr name | CLI binary name and integration identifier |
| `clients.<name>.base_url` | string | — | Base URL of the Paperless-ngx instance |
| `clients.<name>.cli.enabled` | bool | `true` | Install per-client CLI wrapper |
| `clients.<name>.claude-code.skill.enabled` | bool | `true` | Install Claude Code agent skills |
| `clients.<name>.agent-skills.enabled` | bool | `false` | Distribute skills via agent-skills module |
| `clients.<name>.openclaw.skill.enabled` | bool | `false` | Add OpenClaw skills |
| `clients.<name>.agent-deck.skill.enabled` | bool | `false` | Add skills to agent-deck pool |
