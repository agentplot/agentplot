## 1. Wire agent-skills-nix HM module

- [x] 1.1 Import `agent-skills-nix` HM module in `modules/agentplot.nix` so `programs.agent-skills` options are defined in the evaluation context
- [x] 1.2 Verify flake lock includes the `agent-skills-nix` input (run `nix flake lock` if needed)

## 2. Add Phase 1 / Phase 2 mutual exclusion guard

- [x] 2.1 In `services/linkding/default.nix`, wrap the `programs.claude-code.skills` assignment with `lib.mkIf (!clientSettings.agent-skills.enabled)` so Phase 1 is suppressed when Phase 2 is active

## 3. Evaluation tests

- [x] 3.1 Create `tests/agent-skills-delegation.nix` — single-client test: one client with `agent-skills.enabled = true`, assert `programs.agent-skills.sources`, `skills.explicit`, and `targets.claude.enable` are set correctly
- [x] 3.2 Extend test for multi-client: two clients with different `cliName` values, assert both `skills.explicit` entries exist with correct transforms and packages
- [x] 3.3 Assert Phase 1 suppression: when `agent-skills.enabled = true`, `programs.claude-code.skills.<cliName>` is NOT set for that client
- [x] 3.4 Run `nix-instantiate --eval tests/agent-skills-delegation.nix` and confirm it passes
