## 1. Fix replaceStrings in clientSkill derivation

- [x] 1.1 Add `"name: linkding"` / `"name: ${cliName}"` pair to the `builtins.replaceStrings` call at line ~262 of `services/linkding/default.nix`

## 2. Fix replaceStrings in agent-skills transform

- [x] 2.1 Add the same `"name: linkding"` / `"name: ${cliName}"` pair to the Phase 2 `agent-skills` transform at line ~327 of `services/linkding/default.nix`

## 3. Verify

- [x] 3.1 Run `nix flake check` to confirm the flake evaluates cleanly
