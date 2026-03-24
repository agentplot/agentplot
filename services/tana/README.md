# tana

Agent skill for exporting and working with Tana knowledge base content. Covers workspace export, supertag-based queries, and conversion to other formats (e.g., Obsidian markdown).

**Upstream:** [tana.inc](https://tana.inc)

## Roles

### Client (client-only)

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| Skill | Tana export and knowledge management skill |

**Available targets:** `claude-code.skill`, `agent-skills`, `openclaw.skill`, `agent-deck.skill`

No CLI or server role. Skill-only service.

## Example Inventory

```nix
{
  services.tana.client.mac = {
    roles = [ "client" ];
    config.clients = {
      default = {
        name = "tana";
        claude-code.skill.enabled = true;
      };
    };
  };
}
```

## Key Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clients.<name>.name` | string | attr name | Integration identifier |
| `clients.<name>.claude-code.skill.enabled` | bool | `true` | Install Claude Code agent skill |
| `clients.<name>.agent-skills.enabled` | bool | `false` | Distribute skill via agent-skills module |
| `clients.<name>.openclaw.skill.enabled` | bool | `false` | Add OpenClaw skill |
| `clients.<name>.agent-deck.skill.enabled` | bool | `false` | Add skill to agent-deck pool |
