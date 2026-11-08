# Verify: guests-by-evaluated-configuration

Verified on `change/guests-by-evaluated-configuration` at `30cfa39`, on aarch64-darwin, 2026-11-08.

**Verdict: the work holds.** The whole checks pass, every requirement and scenario of `specs/microvm-host/spec.md` is met, and every task is ticked done. The change is ready to archive.

## Whole checks

Each was run once, on the branch as it stands. `nix flake check` is the merge gate (`.config/sluice.toml`). The other two are the remaining checks the repository names in `CLAUDE.md`'s Build & Test and `README.md`'s Development block.

| Check | Outcome |
|---|---|
| `nix flake check` | Pass, exit 0. It evaluated `checks.aarch64-darwin.microvm-host-holds-no-source` to `/nix/store/b3jx7rsn497pclkd20q0c1nddlzc8gdm-microvm-host-holds-no-source.drv`, which means the check's verdict passed, along with the packages and NixOS modules. "all checks passed!" It skipped the aarch64-linux, x86_64-darwin and x86_64-linux systems because it ran without `--all-systems`, as the gate does. |
| `nix build --no-link .#linkding-cli` | Pass, exit 0. |
| `nix-instantiate --eval tests/hmModules-composition.nix` | Pass: `"PASS: hmModules composition + claude-code skill delegation — single-client, multi-client, cross-service, client-only, multi-package, miniflux merge"`. |

`nix eval .#checks` lists `microvm-host-holds-no-source` under all four supported systems.

## Requirements and scenarios

The scenarios were tested with a scratch probe: a copy of `tests/microvm-host-holds-no-source.nix` that exposes the check's own `host`, `standIn`, `vms` and reader. It was evaluated against the flake at `30cfa39`, where the consumer's source is `/nix/store/595x46vpgpg2pcrymnhbpsbykm36ahbh-source`.

### A host installs each of its guests from its evaluated configuration — met

- **A guest of this host is installed from its evaluated configuration.** `services/microvm/default.nix` gives each guest `{ evaluatedConfig = self.nixosConfigurations.${name}; autostart = true; }`. In the evaluated host, `microvm.vms.guest.flake` and `microvm.vms.guest.updateFlake` are both `null`. The `evaluatedConfig`'s toplevel `drvPath` equals the consumer's `nixosConfigurations.guest`'s.
- **A guest of another host is not installed.** The host's `microvm.vms` names are exactly `[ "guest" ]`, and `elsewhere` (assigned to `other`) is absent.

### A host's closure holds its guests' systems and none of the flake's source — met

- **The install unit refers to the guest's system.** The string context of `install-microvm-guest`'s script holds exactly the guest's toplevel (`…-nixos-system-guest-26.05.20260318.9cf7092.drv`) and its declared runner (`…-microvm-cloud-hypervisor-guest.drv`).
- **The install unit refers to none of the flake's source.** That context holds no `…-source` path. The script links `current` to the runner and `toplevel` to the guest's system, and it writes no `flake` file. The stand-in host's script, for comparison, does `echo '/nix/store/595x…-source' > flake`.

### The merge gate fails a host that holds the flake's source — met

- **A host role that installs a guest from the flake fails the gate.** At `55e0bae` the check was in place and the role still handed microvm.nix `flake = self`. There, `nix flake check` fails (exit 1) with `microvm-host-holds-no-source: A host installs each of its guests from its evaluated configuration: the host installs it from a flake: guest`.
- **The reader is proven before it is trusted.** At `30cfa39` the reader finds the source in the stand-in host's `install-microvm-guest` script. A mutated copy of the check, whose stand-in keeps the role's `evaluatedConfig` install, fails first with `…: The merge gate fails a host that holds the flake's source: the reader is blind, finding no source in the install unit of a stand-in host that installs from the flake: guest`. Because the verdict is joined with `&&`, the reader's proof is evaluated before any later step.
- **A host role that installs guests from their evaluated configurations passes the gate.** `nix flake check` passes at `30cfa39` (see Whole checks).

## Tasks

All five tasks (1.1–1.3, 2.1–2.2) are ticked, and each one's own verification holds at `30cfa39`:

- 1.1: the check is a function `{ self }: pkgs: <derivation>`, throws in design.md decision 3's six-step order, and ends in a `runCommand` that touches `$out`.
- 1.2: `flake.nix` imports the check once and sets it for every system in `supportedSystems`. It fails at `55e0bae` with step 2's message, as shown above.
- 1.3: `README.md` names the check in the outputs table and the Development block, and `CLAUDE.md` names it in Flake Structure.
- 2.1: the role hands microvm.nix `evaluatedConfig`, and the check passes.
- 2.2: `services/microvm/README.md`'s Host section and the microvm gotchas in `services/CLAUDE.md` say the host installs from the evaluated configuration. The gotcha names the check.

The workflow follow-up, archiving with `microvm-host` synced into `openspec/specs/`, is done by this stage's archive.

## Coherence

- design.md decision 3's step 5 now checks the guest's declared runner as well as its toplevel. That makes the design match the spec's "refers to `guest`'s system toplevel and to `guest`'s declared runner".
- `openspec validate guests-by-evaluated-configuration --strict`: valid.
- The commits are conventional. The role change is marked `!`, with a `BREAKING CHANGE` footer matching the proposal.
