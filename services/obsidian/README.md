# obsidian

Knowledge management with vault-aware agent skills for note search, creation, linking, and PARA-based organization. Supports multiple vault profiles with optional syncthing synchronization.

**Upstream:** [obsidianmd/obsidian](https://obsidian.md)

## Roles

### Client (client-only)

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| Skills | Obsidian vault management + PARA organization skill |
| CLI | Per-client obsidian-cli wrapper (if package provided) |

**Available targets:** `claude-code.skill`, `agent-skills`, `openclaw.skill`, `agent-deck.skill`, `cli` (when obsidian-cli available)

No server role. Vault storage and syncthing folder wiring are consumer responsibilities.

## Example Inventory

```nix
{
  services.obsidian.client.mac = {
    roles = [ "client" ];
    config.clients = {
      personal = {
        name = "obsidian";
        vaults = [ "Personal" "Creative" ];
        vaultBasePath = "~/Documents/Obsidian";
        syncthing.enable = true;
        claude-code.skill.enabled = true;
      };
      business = {
        name = "obsidian-biz";
        vaults = [ "Business" ];
      };
    };
  };
}
```

## Key Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clients.<name>.name` | string | attr name | CLI binary name and integration identifier |
| `clients.<name>.vaults` | list of string | `[]` | Obsidian vault names for this client |
| `clients.<name>.vaultBasePath` | string | `"~/Documents/Obsidian"` | Base directory containing vaults |
| `clients.<name>.syncthing.enable` | bool | `true` | Flag for consumer-level syncthing wiring |
| `clients.<name>.claude-code.skill.enabled` | bool | `true` | Install Claude Code agent skills |
| `clients.<name>.agent-skills.enabled` | bool | `false` | Distribute skills via agent-skills module |
| `clients.<name>.openclaw.skill.enabled` | bool | `false` | Add OpenClaw skills |
| `clients.<name>.agent-deck.skill.enabled` | bool | `false` | Add skills to agent-deck pool |
