## ADDED Requirements

### Requirement: OpenClaw server role ported from swancloud
The openclaw clanService SHALL include a `roles.server` definition ported from `swancloud/clanServices/openclaw/default.nix`. The server role provides the OpenClaw gateway with Caddy HTTPS, model providers, agents, channels (telegram/discord/bluebubbles), plugin support, and clan vars generators for secrets.

#### Scenario: Server role deploys gateway with Caddy
- **WHEN** the openclaw server role is enabled with a configured domain
- **THEN** Caddy SHALL serve a virtualHost with cloudflare TLS config and reverse_proxy to the gateway port

#### Scenario: Provider API keys managed via clan vars
- **WHEN** providers are configured (e.g., anthropic, openai)
- **THEN** a clan vars generator SHALL be created for each provider with a prompted API key secret

#### Scenario: Telegram channel with per-account bot tokens
- **WHEN** `channels.telegram.enable = true` and accounts are configured
- **THEN** per-account clan vars generators SHALL be created for bot tokens, and the OpenClaw config SHALL wire bot token files into account settings

#### Scenario: Gateway runs as openclaw system user
- **WHEN** the server role is enabled
- **THEN** an `openclaw` system user with linger SHALL be created, and the gateway SHALL run as a home-manager user service under that user

### Requirement: OpenClaw node role ported from swancloud
The openclaw clanService SHALL include a `roles.node` definition that connects to a remote gateway.

#### Scenario: Node connects to remote gateway
- **WHEN** a node role is enabled and a server role exists in the inventory
- **THEN** the node SHALL configure `gateway.mode = "remote"` with the server's domain and a shared gateway token

#### Scenario: Node works on both NixOS and Darwin
- **WHEN** the node role is instantiated
- **THEN** both `nixosModule` and `darwinModule` SHALL be provided with appropriate user/group settings
