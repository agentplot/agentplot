## Why

Multiple agentplot services (linkding today, paperless and others in future) need OIDC authentication. The current implementation hardcodes Kanidm-specific endpoint URL construction directly in each service's NixOS module, creating duplication and vendor lock-in. A shared OIDC interface module would standardize how services consume OIDC configuration while keeping Kanidm as a first-class convenience provider.

## What Changes

- Add a generic OIDC interface module at `modules/oidc.nix` that defines provider-agnostic OIDC options (`enable`, `provider`, `issuerUrl`, `clientId`, `clientSecretFile`, explicit endpoint overrides)
- Add a Kanidm provider convenience layer that auto-derives OIDC endpoint URLs from `issuerUrl` + `clientId`, matching Kanidm's URL structure
- Support explicit endpoint override for non-Kanidm providers or custom configurations
- Refactor linkding server role to consume the shared OIDC module instead of inline Kanidm-specific logic
- Secret flow uses `clan.core.vars` generators with a prompted secret (consistent with existing patterns)

## Capabilities

### New Capabilities
- `oidc-interface`: Shared OIDC configuration module with generic provider support and Kanidm convenience layer

### Modified Capabilities

## Impact

- `modules/oidc.nix` — new shared module
- `services/linkding/default.nix` — server role refactored to consume shared OIDC interface
- `flake.nix` — expose new module in outputs
- Future services gain standardized OIDC integration by importing the shared module
