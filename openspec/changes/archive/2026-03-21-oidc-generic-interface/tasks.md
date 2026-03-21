## 1. Shared OIDC Module

- [x] 1.1 Create `modules/oidc.nix` with `agentplot.oidc.clients.<name>` option namespace (submodule with `enable`, `provider`, `issuerUrl`, `clientId`, `signAlgorithm`, and `endpoints.*` options)
- [x] 1.2 Implement Kanidm endpoint auto-derivation logic (derive endpoints from `issuerUrl` + `clientId` when `provider = "kanidm"`)
- [x] 1.3 Support explicit endpoint overrides that take precedence over auto-derived values
- [x] 1.4 Add `clan.core.vars` generator per enabled client (`oidc-{clientName}`) with prompted client secret

## 2. Flake Integration

- [x] 2.1 Expose `modules/oidc.nix` in `flake.nix` as `nixosModules.oidc` and `darwinModules.oidc`

## 3. Linkding Refactor

- [x] 3.1 Refactor linkding server role `perInstance` to set up `agentplot.oidc.clients.linkding` from its interface settings
- [x] 3.2 Replace inline Kanidm endpoint URL construction with reads from `config.agentplot.oidc.clients.linkding.endpoints.*`
- [x] 3.3 Replace inline `kanidm-oidc-*` vars generator with shared module's `oidc-linkding` generator path

## 4. Verification

- [x] 4.1 Add evaluation test in `tests/` to verify OIDC module composition (Kanidm provider with auto-derived endpoints)
- [x] 4.2 Verify `nix flake check` passes
