# openclaw

AI assistant gateway with multi-channel support (Telegram, Discord, iMessage via BlueBubbles), agent routing, and a full CLI ecosystem for workspace management and workflow automation.

**Upstream:** [openclaw/nix-openclaw](https://github.com/openclaw/nix-openclaw)

## Roles

### Server

Deploys the OpenClaw gateway as a home-manager user service under a dedicated `openclaw` system user. Includes Caddy reverse proxy, per-provider API key management via clan vars, and multi-channel configuration.

### Node

Connects to a remote gateway. Provides both NixOS and Darwin modules. Reads the server's domain and shared gateway token from the inventory.

### Client

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| Skill | Workspace management skill (project scaffolding, workflow orchestration) |
| Extra packages | lobster, clawhub, imsg, gogcli, remindctl, blogwatcher, memo, defuddle |

**Available targets:** `claude-code.skill`, `agent-skills`, `openclaw.skill`, `agent-deck.skill`

No CLI wrapper — packages are installed globally via `extraPackages`.

## Example Inventory

```nix
{
  services.openclaw.server.gateway-vm = {
    roles = [ "server" ];
    config = {
      domain = "openclaw.swancloud.net";
      ip = "10.0.0.5";
      providers = {
        anthropic = {};
        openai = {};
      };
      agents = [
        { id = "dispatch"; name = "Dispatch"; default = true; }
        { id = "research"; name = "Research"; model = "anthropic/claude-sonnet-4-20250514"; }
      ];
      channels.telegram = {
        enable = true;
        allowFrom = [ 123456789 ];
        accounts.dispatch-bot = {
          dmPolicy = "pairing";
          groupPolicy = "allowlist";
        };
      };
      bindings = [
        { agentId = "dispatch"; channel = "telegram"; accountId = "dispatch-bot"; }
      ];
    };
  };

  services.openclaw.node.mac = {
    roles = [ "node" ];
    config.bundledPlugins = {};
  };

  services.openclaw.client.mac = {
    roles = [ "client" ];
    config.clients.default = {
      name = "openclaw";
      claude-code.skill.enabled = true;
    };
  };
}
```

## Key Options

### Server

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `domain` | string | — | FQDN for the gateway |
| `ip` | string | — | Microvm IP on the bridge network |
| `port` | port | `18789` | Gateway listen port |
| `providers` | attrsOf { apiKeyFile } | `{}` | Model providers (keys prompted via clan vars) |
| `agents` | list of { id, name, default?, model? } | `[]` | Agent definitions |
| `agentDefaults.model` | string | `"anthropic/claude-sonnet-4-20250514"` | Default model |
| `agentDefaults.thinkingDefault` | enum | `"high"` | Default thinking level |
| `bindings` | list of { agentId, channel, accountId } | `[]` | Agent-to-channel bindings |
| `channels.telegram.enable` | bool | `false` | Enable Telegram |
| `channels.telegram.accounts` | attrsOf { dmPolicy, groupPolicy, streamMode } | `{}` | Telegram bot accounts |
| `channels.discord.enable` | bool | `false` | Enable Discord |
| `channels.bluebubbles.enable` | bool | `false` | Enable iMessage via BlueBubbles |
| `plugins` | list of attrs | `[]` | Custom plugins |
| `bundledPlugins` | attrs | `{}` | Bundled plugin toggles |

### Node

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `plugins` | list of attrs | `[]` | Node-local plugins |
| `bundledPlugins` | attrs | `{}` | Bundled plugin toggles |

### Client

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clients.<name>.name` | string | attr name | Integration identifier |
| `clients.<name>.claude-code.skill.enabled` | bool | `true` | Install Claude Code agent skill |
| `clients.<name>.agent-skills.enabled` | bool | `false` | Distribute skill via agent-skills module |
