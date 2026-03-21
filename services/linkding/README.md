# linkding clanService

Bookmark manager with agent tooling. Provides a **server** role (OCI container, PostgreSQL, Caddy reverse proxy) and a **client** role (CLI wrappers, agent skills, HM delegation).

## Roles

### Server

Deploys a linkding instance as an OCI container with PostgreSQL backend and Caddy reverse proxy.

```nix
clan.modules.linkding.roles.server.machines = [ "myhost" ];
clan.modules.linkding.roles.server.settings = {
  domain = "links.example.com";
  # Optional: OIDC via Kanidm
  oidc.enable = true;
  oidc.issuerDomain = "auth.example.com";
};
```

### Client

Generates per-client CLI wrappers, agent skills, and HM modules. Supports multiple named clients pointing at different linkding instances.

```nix
clan.modules.linkding.roles.client.machines = [ "workstation" ];
clan.modules.linkding.roles.client.settings.clients = {
  personal = {
    name = "linkding";              # CLI binary name and skill identifier
    base_url = "https://links.example.com";
  };
  biz = {
    name = "linkding-biz";
    base_url = "https://links.corp.example.com";
  };
};
```

## Client Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | required | CLI binary name and skill identifier |
| `base_url` | string | required | Base URL of the linkding instance |
| `default_tags` | list of string | `[]` | Default tags for bookmarks |
| `cli.enabled` | bool | `true` | Install the CLI wrapper |
| `claude-code.skill.enabled` | bool | `true` | Install Claude Code agent skill |
| `agent-skills.enabled` | bool | `false` | Distribute skill via agent-skills-nix (Phase 2) |
| `openclaw.skill.enabled` | bool | `false` | Add OpenClaw skill (Phase 2) |
| `claude-tools.enabled` | bool | `false` | Install via claude-plugins marketplace (Phase 2) |

### MCP Not Supported

linkding does not have an MCP server. The following options exist for interface compatibility but will produce an evaluation error if enabled:

- `claude-code.mcp.enabled`
- `claude-code.profiles.<name>.mcp.enabled`
- `agent-deck.mcp.enabled`

Use the CLI skill instead — it provides full API coverage via restish.

## How It Works

Each client generates:

1. **CLI wrapper** — a shell script that reads the API token from clan vars, sets `LINKDING_API_TOKEN` and `LINKDING_BASE_URL`, and execs `linkding-cli` (a restish wrapper with the bundled OpenAPI spec).

2. **Agent skill** — a `SKILL.md` installed to `~/.claude/skills/<name>/SKILL.md` with all CLI command references and the frontmatter `name:` field substituted to match the client name.

3. **HM module** — accumulated via `agentplot.hmModules` and wired into the user's Home Manager config by `modules/agentplot.nix`.

## Secrets

API tokens are managed via clan vars generators. On first deployment, you'll be prompted for each client's token:

```
API token for linkding client 'personal' at https://links.example.com:
```

Tokens are stored encrypted and read at runtime by the CLI wrapper. The agent skill does not need direct access to secrets or environment variables.
