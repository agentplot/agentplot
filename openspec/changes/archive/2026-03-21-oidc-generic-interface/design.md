## Context

Linkding's server role currently hardcodes Kanidm-specific OIDC endpoint URLs (lines 108-114 of `services/linkding/default.nix`). The endpoint construction pattern (`/ui/oauth2`, `/oauth2/token`, `/oauth2/openid/{clientId}/userinfo`, etc.) is Kanidm-specific. As more services need OIDC (paperless, future services), this logic would be duplicated.

The existing secret flow uses `clan.core.vars` generators with a `kanidm-oidc-{machine.name}` generator. The interface options (`oidc.enable`, `oidc.issuerDomain`) live directly in linkding's server role interface.

## Goals / Non-Goals

**Goals:**
- Define a shared NixOS option namespace (`agentplot.oidc`) with provider-agnostic OIDC configuration
- Provide a Kanidm convenience layer that auto-derives endpoint URLs from issuer domain + client ID
- Allow explicit endpoint overrides for any OIDC provider
- Refactor linkding to consume the shared module, eliminating inline endpoint construction
- Maintain the `clan.core.vars` prompted-secret pattern for client secrets

**Non-Goals:**
- Building a Kanidm clanService with automated provisioning (future work)
- OIDC discovery (`.well-known/openid-configuration`) auto-fetch at build time — Nix evaluation is pure
- Supporting multiple OIDC providers per service simultaneously
- Client-side (HM) OIDC configuration — this is server-side only

## Decisions

### 1. Shared module at `modules/oidc.nix` with per-service client submodules

The module defines `agentplot.oidc.clients.<name>` where each client represents a service's OIDC registration. This is an attrset of submodules, each with: `enable`, `provider`, `issuerUrl`, `clientId`, `signAlgorithm`, and explicit endpoint options (`endpoints.authorization`, `endpoints.token`, `endpoints.userinfo`, `endpoints.jwks`). The client secret path is accessed via the vars generator convention (`config.clan.core.vars.generators."oidc-{name}".files."client-secret".path`) rather than a submodule option, avoiding circular module evaluation.

**Why not per-service inline options?** Centralizing avoids duplication and ensures all services configure OIDC identically. Services read from `config.agentplot.oidc.clients.<name>` rather than defining their own option trees.

**Why not a single global OIDC config?** Multiple services need distinct client IDs and potentially different providers. The `clients.<name>` attrset naturally maps to service registrations.

### 2. Provider enum with Kanidm as first-class value

`provider` is a string enum: `"kanidm"` | `"generic"`. When set to `"kanidm"`, endpoint URLs are auto-derived:
- `authorization` = `https://{issuerUrl}/ui/oauth2`
- `token` = `https://{issuerUrl}/oauth2/token`
- `userinfo` = `https://{issuerUrl}/oauth2/openid/{clientId}/userinfo`
- `jwks` = `https://{issuerUrl}/oauth2/openid/{clientId}/public_key.jwk`

When set to `"generic"`, all four endpoints MUST be explicitly provided. This keeps the convenience of Kanidm while being fully extensible.

**Alternative considered:** OIDC discovery via IFD (import-from-derivation) to fetch `.well-known` at build time. Rejected because IFD is impure, breaks evaluation caching, and requires network at build time.

### 3. Secret flow via clan.core.vars prompted generator

Each OIDC client gets a `clan.core.vars` generator named `oidc-{clientName}` that prompts for the client secret. The module creates the generator and exposes the secret file path. Services read `clientSecretFile` from the module config.

**Why prompted over cross-service reference?** Kanidm provisioning automation doesn't exist yet. The prompted approach is the simplest working pattern, consistent with existing `linkding-db-password` and API token generators. A future Kanidm clanService could replace the prompted generator with an automated one.

### 4. Linkding consumes shared module, drops inline OIDC options

Linkding's server role interface keeps `oidc.enable` and `oidc.issuerDomain` for backward compatibility with existing clan inventories, but the NixOS module implementation reads endpoint URLs from `config.agentplot.oidc.clients.linkding` instead of constructing them inline. The server role's `perInstance` module sets up the shared OIDC client config based on its interface settings.

## Risks / Trade-offs

- **[Coupling between service interface and shared module]** → Services must coordinate their interface options with the shared module's client config. Mitigation: The service's `perInstance` module is the natural place to bridge these — it reads interface settings and writes to the shared module's config.

- **[Kanidm URL structure changes]** → If Kanidm changes its endpoint URL pattern, the convenience layer breaks. Mitigation: Explicit endpoint overrides always available; Kanidm URL pattern is stable across major versions.

- **[No runtime OIDC discovery]** → Endpoints are baked at build time, not fetched from `.well-known`. Mitigation: This is consistent with Nix's pure evaluation model. Runtime discovery would require a systemd oneshot or similar, adding complexity for marginal benefit when endpoints rarely change.
