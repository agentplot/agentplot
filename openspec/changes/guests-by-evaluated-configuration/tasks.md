## 1. The gate's check

- [x] 1.1 Write `tests/microvm-host-holds-no-source.nix` as design.md decision 3 describes: a function `{ self }: pkgs: <derivation>` that evaluates the service's guest and host roles, with the clan-core and sops-nix option stubs, into an `x86_64-linux` guest, host and stand-in host, reads each `install-microvm-<guest>` script's string context for the consumer's `outPath`, throws in the six steps' order with messages naming the requirement and each guest, and otherwise returns a `pkgs.runCommand` that touches `$out`. Stage it with `git add` so the flake sees it, and verify it parses: `nix-instantiate --parse tests/microvm-host-holds-no-source.nix > /dev/null`
- [x] 1.2 Give `flake.nix` a `checks` output that imports the check once with `self` and sets `checks.<system>.microvm-host-holds-no-source` for every system of `supportedSystems`. With the host role still handing microvm.nix `flake = self`, verify that `nix build --no-link ".#checks.$(nix config show system).microvm-host-holds-no-source"` fails with step 2's message naming `guest`, the stand-in having passed step 1
- [x] 1.3 Name the check in `README.md` (a `checks.<system>.microvm-host-holds-no-source` row in the flake outputs table, and its `nix build` command in the Development block) and in `CLAUDE.md`'s Flake Structure outputs, and verify both name it: `grep -n 'microvm-host-holds-no-source' README.md CLAUDE.md`

## 2. Guests by their evaluated configuration

- [x] 2.1 In `services/microvm/default.nix`, have the host role give each of its guests `{ evaluatedConfig = self.nixosConfigurations.${name}; autostart = true; }`, with no `flake` and no `updateFlake`, and verify the check now passes: `nix build --no-link ".#checks.$(nix config show system).microvm-host-holds-no-source"`
- [ ] 2.2 Document how a host installs its guests, as design.md decision 4 describes: in `services/microvm/README.md`'s Host section (installed from each guest's evaluated configuration, its closure holding the guest's system and none of the flake's source, a guest moving with its host's deploy and not with `microvm -u`) and in the Microvm guests gotchas of `services/CLAUDE.md` (never `flake = self`, and why, naming the check). Verify both say it: `grep -n 'evaluated configuration' services/microvm/README.md services/CLAUDE.md && grep -n 'microvm-host-holds-no-source' services/CLAUDE.md`

## Workflow follow-up

- Archive the change once it is verified, syncing `microvm-host` into `openspec/specs/`.
