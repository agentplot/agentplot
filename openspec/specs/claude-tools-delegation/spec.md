## ADDED Requirements

### Requirement: Single client skill registration
When a linkding client has `claude-tools.enabled = true`, the client's HM module SHALL set `programs.claude-tools.skills-installer.skillsByClient.claude-code.<cliName>` to `"symlink"`, where `<cliName>` is the client's configured `name` value.

#### Scenario: Single client with claude-tools enabled
- **WHEN** a linkding client is configured with `name = "linkding"` and `claude-tools.enabled = true`
- **THEN** the composed HM config SHALL contain `programs.claude-tools.skills-installer.skillsByClient.claude-code.linkding` equal to `"symlink"`

#### Scenario: Client with claude-tools disabled
- **WHEN** a linkding client is configured with `claude-tools.enabled = false` (the default)
- **THEN** the composed HM config SHALL NOT contain any `programs.claude-tools` attributes from that client

### Requirement: Multi-client merge within a single service
When multiple linkding clients each have `claude-tools.enabled = true`, their `skillsByClient` contributions SHALL merge without conflict under the same `claude-code` attribute set.

#### Scenario: Two linkding clients both enabled
- **WHEN** client `linkding` and client `linkding-biz` both have `claude-tools.enabled = true`
- **THEN** `skillsByClient.claude-code` SHALL contain both `linkding = "symlink"` and `linkding-biz = "symlink"`

### Requirement: Cross-service merge via attrsOf
When multiple clanServices contribute to `programs.claude-tools.skills-installer.skillsByClient`, the NixOS module system's `attrsOf` merge SHALL combine all entries without conflict.

#### Scenario: Two services contributing to skillsByClient
- **WHEN** linkding contributes `skillsByClient.claude-code.linkding = "symlink"` and a second service contributes `skillsByClient.claude-code.paperless = "symlink"`
- **THEN** `skillsByClient.claude-code` SHALL contain all three entries: `linkding`, `linkding-biz`, and `paperless`, each set to `"symlink"`

### Requirement: Nix evaluation test validates delegation
A Nix evaluation test SHALL assert the correctness of `skillsByClient` output for single-client, multi-client, and cross-service scenarios.

#### Scenario: Test passes on correct composition
- **WHEN** `nix-instantiate --eval` is run against the claude-tools delegation test
- **THEN** the evaluation SHALL succeed without errors, confirming all `skillsByClient` assertions hold
