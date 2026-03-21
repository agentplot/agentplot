## 1. Create OpenClaw skill delegation test

- [x] 1.1 Create `tests/openclaw-skill-delegation.nix` with mock `programs.openclaw` module defining `programs.openclaw.skills` as `lib.types.listOf lib.types.attrs`
- [x] 1.2 Add single-client test case: one linkding client with `openclaw.skill.enabled = true`, assert `programs.openclaw.skills` has one entry with correct name, mode, and non-empty content
- [x] 1.3 Add disabled-client test case: client with `openclaw.skill.enabled = false`, assert no skills entry produced
- [x] 1.4 Add multi-client test case: two clients ("personal" with name "linkding", "biz" with name "linkding-biz") both enabled, assert two distinct entries in skills list
- [x] 1.5 Add mixed-enabled test case: one client enabled, one disabled, assert exactly one entry
- [x] 1.6 Add content substitution assertion: verify skill content for "linkding-biz" client references "linkding-biz" not "linkding-cli"

## 2. Wire test into flake check

- [x] 2.1 No `checks` output exists in flake.nix — tests run standalone via `nix-instantiate --eval` (consistent with existing pattern)
- [x] 2.2 Verify test passes with `nix-instantiate --eval tests/openclaw-skill-delegation.nix`

## 3. Verify end-to-end

- [x] 3.1 Run the full test and confirm all assertions pass
- [x] 3.2 Run existing `hmModules-composition.nix` test to confirm no regressions
