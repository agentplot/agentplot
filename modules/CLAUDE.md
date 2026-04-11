# modules/

Shared NixOS/Darwin modules imported by the flake as `nixosModules.*` and `darwinModules.*`. These are consumed by deployment inventories, not by services directly (except `oidc.nix` which services import).

## agentplot.nix — HM Delegation Adapter

The central composition module. It accumulates Home Manager modules from all configured clanService client roles and wires them into a single user's Home Manager config.

**Options:**
- `agentplot.user` — username to target (null = disabled)
- `agentplot.hmModules` — attrset of `<service>-<client>` → deferred HM module (populated by mkClientTooling)
- `agentplot.hmBaseModules` — framework-level HM modules (e.g., agent-skills-nix) imported alongside per-service modules
- `agentplot.serialization` — JSON-serializable snapshot of evaluated capabilities for dashboard generation
- `agentplot._contributedCliTools` — internal: CLI tool names for serialization

**How it works:** When `user` is set and `hmModules` is non-empty, it creates `home-manager.users.${user}.imports` from all accumulated modules. This lets 13 services coexist without conflicts.

**Serialization** produces a machine-level capabilities snapshot (`{ machine, user, mcpServers, skills, cliTools, agentDeckMcps, profiles }`) used by `lib.mkCapabilitiesDashboard` to build cross-machine views.

## oidc.nix — OIDC Client Registration

Declarative OIDC client interface used by services with optional SSO (linkding, miniflux, paperless).

**Options:** `agentplot.oidc.clients.<name>` with per-client submodule:
- `provider` — `"kanidm"` (auto-derives endpoints from issuerUrl) or `"generic"` (explicit endpoint URLs)
- `clientId`, `issuerUrl`, `signAlgorithm`

Auto-generates `clan.core.vars.generators."oidc-<name>"` for client secret provisioning.

**Usage from services:** `imports = [ ../../modules/oidc.nix ];` then set `agentplot.oidc.clients.<name>`.

## dashboards.nix — Static Dashboard Serving

Serves dashboard derivations (HTML) via Caddy.

**Options:** `agentplot.dashboards.{ enable, domain, sites }` where `sites` is an attrset of name → derivation containing `index.html`. Each site is served at `/<name>/` under the configured domain.
