## 1. Test Harness Setup

- [x] 1.1 Add a `programs.claude-tools.skills-installer.skillsByClient` option stub (attrsOf (attrsOf str)) to the existing `tests/hmModules-composition.nix` test harness
- [x] 1.2 Update mock linkding clanService HM module to accept a `claude-tools.enabled` parameter and conditionally write to `skillsByClient`

## 2. Single-Client Delegation

- [x] 2.1 Configure mock linkding client with `claude-tools.enabled = true` and `name = "linkding"`
- [x] 2.2 Add assertion that `skillsByClient.claude-code.linkding` equals `"symlink"`

## 3. Multi-Client Merge

- [x] 3.1 Add a second mock linkding client (`linkding-biz`) with `claude-tools.enabled = true`
- [x] 3.2 Add assertion that `skillsByClient.claude-code` contains both `linkding` and `linkding-biz`

## 4. Cross-Service Merge

- [x] 4.1 Add a second mock clanService (e.g., paperless) that contributes `skillsByClient.claude-code.paperless = "symlink"`
- [x] 4.2 Add assertion that `skillsByClient.claude-code` contains entries from both services (`linkding`, `linkding-biz`, `paperless`)

## 5. Verification

- [x] 5.1 Run `nix-instantiate --eval tests/hmModules-composition.nix` and confirm all assertions pass
