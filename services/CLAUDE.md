# services/

Each subdirectory is a **clanService** — a self-contained unit that bundles infrastructure (NixOS modules), CLI packages, agent skills, and Home Manager delegation into a single Nix expression.

## clanService Architecture

Every service is a `default.nix` that returns an attrset with:

```nix
{
  _class = "clan.service";
  manifest = { name, description, categories };
  roles.<roleName> = { description, interface, perInstance };
}
```

Services are consumed by deployment inventories (e.g., swancloud) via `clan.modules.<name>`. The inventory assigns machines to roles and provides per-instance settings.

## Roles

Roles partition a service into independently deployable concerns. Each role has:

- **interface** — NixOS module options (the settings the inventory provides)
- **perInstance** — NixOS module config generated from those settings

### Role Types

| Pattern | Roles | Examples |
|---------|-------|----------|
| **server + client** | `server` runs infrastructure, `client` provides agent tooling | linkding, gno, qmd, subcog, ogham-mcp, miniflux, paperless, atomic |
| **client-only** | No server — wraps an external tool with skills/CLI | tana, obsidian, himalaya |
| **host + guest** | `host` creates VMs, `guest` configures the VM interior | microvm |

### Server Role Conventions

- **No local PostgreSQL** — server roles never define `services.postgresql`. Database provisioning happens on the host via `clan.core.postgresql` in the consuming inventory.
- **DB host hardcoded** — services connect to `10.0.0.1:5432` (bridge gateway).
- **DB passwords via env file** — use `clan.core.vars.generators` shared password + a root oneshot service that writes `/run/<service>.env`. Never put secrets in static `environment` blocks.
- **Caddy TLS** — all server roles reference `config.caddy-cloudflare.tls` from agentplot-kit (not a local copy).
- **Overlay packages** — qmd and gno use `pkgs.llm-agents.qmd`/`pkgs.llm-agents.gno` via overlay, not flake inputs.
- **State** — use `clan.core.state.<name>.folders` for persistent paths, not `services.borgbackup.jobs`.

### Client Role Pattern

**All client roles use `mkClientTooling` from agentplot-kit.** Do NOT hand-write client roles. The function generates interface, perInstance, HM delegation, vars generators, and target wiring from a capabilities declaration:

```nix
roles.client =
  let
    tooling = mkClientTooling {
      serviceName = "myservice";
      capabilities = { ... };      # what the client provides
      extraClientOptions = { ... }; # per-instance settings beyond defaults
    };
  in {
    description = "...";
    inherit (tooling) interface perInstance;
  };
```

## Capabilities System

The `capabilities` attrset in `mkClientTooling` declares what agent tooling a client role provides. Each capability is optional — include only what the service needs.

### skills

Agent skill files (SKILL.md or directories) delegated to `programs.claude-code.skills` via Home Manager.

```nix
capabilities.skills = [ ./skills/SKILL.md ./skills/para ];
```

### cli

A shell wrapper package with environment variables, delegated to `home.packages`.

```nix
capabilities.cli = {
  package = ./packages/myservice-cli;     # path to callPackage-able dir
  wrapperName = client: "myservice-${client.name}";
  envVars = client: {                      # injected into the wrapper
    MY_DOMAIN = client.domain;
    MY_TOKEN = "$(cat ${client.tokenPath})";
  };
};
```

### mcp

MCP server endpoint, delegated to `programs.claude-code.mcpServers` and `programs.agent-deck.mcps`.

```nix
capabilities.mcp = {
  type = "http";                                   # or "sse"
  urlTemplate = client: "https://${client.domain}/mcp";
  extraConfig = client: {                          # optional additional config
    tokenFile = client.secretPaths."jwt-token";
  };
};
```

### secret

Secrets provisioned via `clan.core.vars.generators`. Three modes:

```nix
# Prompted — user provides the value
capabilities.secret = {
  name = "api-token";
  mode = "prompted";
  description = client: "API token for ${client.name}";
};

# Shared — references a server-side generator
capabilities.secret = [
  { name = "db-password"; mode = "shared"; generator = "subcog-db-password"; file = "password"; }
  { name = "jwt-token";   mode = "shared"; generator = "subcog-jwt-token";   file = "token"; }
];
```

### extraPackages

Additional packages added to `home.packages` (e.g., `enex2paperless` for paperless).

### extraClientOptions

Per-instance options beyond the defaults (domain, namespace, vaults, etc.). These become fields on each `client` attrset passed to capability functions.

## Service Variants

### Conditional capabilities

Obsidian demonstrates optional capabilities based on input availability:

```nix
{ mkClientTooling, obsidian-cli ? null, ... }:
# ...
capabilities = {
  skills = [ ./skills/SKILL.md ];
} // (if obsidian-cli != null then { cli = { ... }; } else { });
```

### OIDC integration

Services with optional OIDC (linkding, miniflux, paperless) import `../../modules/oidc.nix` and conditionally configure `agentplot.oidc.clients.<name>`.

### Complex server config

Gno/qmd demonstrate declarative config generation — Nix writes a YAML/JSON config file, `ExecStartPre` installs it, the service reads it.

## Gotchas

### mkClientTooling
- Skill keys MUST include serviceName: `${serviceName}-${clientNameId}` — bare clientNameId collides across services
- `writeShellApplication` runs shellcheck — use `VAR="$(cmd)"; export VAR` not `export VAR="$(cmd)"`
- `lib.isPath` returns false for derivations — check `builtins.isAttrs content && content ? outPath` for derivation paths
- `programs.claude-code.skills` values can be strings, paths, OR derivations (from mkSkillDir)

### Miniflux-specific
- NixOS miniflux module types `CREATE_ADMIN`, `RUN_MIGRATIONS`, `OAUTH2_USER_CREATION` as integers, not strings
- `OAUTH2_OIDC_DISCOVERY_ENDPOINT` wants the issuer URL, NOT the full `/.well-known/openid-configuration` path
- `adminCredentialsFile` must contain `ADMIN_USERNAME=x` and `ADMIN_PASSWORD=x` lines
- DynamicUser can't read sops secrets — use a separate root oneshot to prepare env files
- EnvironmentFile paths validated BEFORE ExecStartPre — use `-` prefix for optional files

### Microvm guests
- All guests need `networking.hostId = lib.mkForce "<unique-8-hex>"` to resolve microvm vs clan-core ZFS conflict
- Guests using llm-agents packages need `nixpkgs.overlays = [ inputs.llm-agents.overlays.default ]`

### State
- `config ? services.borgbackup` is always true (NixOS declares the option) — not a valid guard for conditional borgbackup config
