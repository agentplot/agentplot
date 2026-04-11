# himalaya

Terminal email client with multi-account IMAP/SMTP support and secretspec-based authentication. Enables agent-driven email triage, search, compose, and folder management across multiple accounts.

**Upstream:** [pimalaya/himalaya](https://github.com/pimalaya/himalaya)

## Benefits

- Multi-account email management from a single terminal interface
- Agent-driven inbox triage, search, compose, and reply workflows
- IMAP/SMTP connectivity with secretspec-based authentication
- No server deployment needed -- connects directly to external mail providers

## Roles

| Role | Description |
|------|-------------|
| client | Agent tooling and CLI wrappers for multi-account email via IMAP/SMTP |

### Client (client-only)

Provides agent tooling via `mkClientTooling`:

| Capability | Description |
|-----------|-------------|
| Skill | Email management skill covering inbox triage, search, compose, reply |
| CLI | Per-client himalaya wrapper |

**Available targets:** `claude-code.skill`, `agent-skills`, `openclaw.skill`, `agent-deck.skill`, `cli`

No server role — himalaya connects to external IMAP/SMTP servers.

## Example Inventory

```nix
{
  services.himalaya.client.mac = {
    roles = [ "client" ];
    config.clients = {
      personal = {
        name = "himalaya";
        accounts = {
          icloud = {
            email = "user@icloud.com";
            displayName = "Jane Doe";
            default = true;
            backend = {
              host = "imap.mail.me.com";
              port = 993;
              login = "user@icloud.com";
              passwordKey = "HIMALAYA_ICLOUD_PASSWORD";
            };
            smtp = {
              host = "smtp.mail.me.com";
              port = 587;
              login = "user@icloud.com";
              encryption = "start-tls";
              passwordKey = "HIMALAYA_ICLOUD_SMTP_PASSWORD";
            };
          };
          work = {
            email = "jane@company.com";
            displayName = "Jane Doe";
            backend = {
              host = "imappro.zoho.com";
              port = 993;
              login = "jane@company.com";
              passwordKey = "HIMALAYA_WORK_PASSWORD";
            };
            smtp = {
              host = "smtppro.zoho.com";
              port = 465;
              login = "jane@company.com";
              passwordKey = "HIMALAYA_WORK_SMTP_PASSWORD";
            };
          };
        };
      };
    };
  };
}
```

## Key Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `clients.<name>.name` | string | attr name | CLI binary name |
| `clients.<name>.accounts` | attrsOf account | `{}` | Email account definitions |
| `clients.<name>.accounts.<acct>.email` | string | — | Email address |
| `clients.<name>.accounts.<acct>.displayName` | string | — | Display name for outgoing mail |
| `clients.<name>.accounts.<acct>.default` | bool | `false` | Whether this is the default account |
| `clients.<name>.accounts.<acct>.backend.type` | string | `"imap"` | Backend type |
| `clients.<name>.accounts.<acct>.backend.host` | string | — | IMAP server hostname |
| `clients.<name>.accounts.<acct>.backend.port` | port | — | IMAP server port |
| `clients.<name>.accounts.<acct>.backend.login` | string | — | IMAP login username |
| `clients.<name>.accounts.<acct>.backend.passwordKey` | string | — | SecretSpec key for IMAP password |
| `clients.<name>.accounts.<acct>.smtp.host` | string | — | SMTP server hostname |
| `clients.<name>.accounts.<acct>.smtp.port` | port | — | SMTP server port |
| `clients.<name>.accounts.<acct>.smtp.login` | string | — | SMTP login username |
| `clients.<name>.accounts.<acct>.smtp.encryption` | null or enum | `null` | `"tls"`, `"start-tls"`, `"none"`, or `null` |
| `clients.<name>.accounts.<acct>.smtp.passwordKey` | string | — | SecretSpec key for SMTP password |
