## Why

The microvm host role hands microvm.nix `flake = self` for every guest it runs, and microvm.nix's `install-microvm-<guest>` unit writes that flake's store path into the guest's state directory. Every host's closure therefore holds the consuming flake's whole source, so every landing, a docs edit among them, changes every host's system and releases it. swancloud's srv already works around this by forcing `flake = null` and giving each guest its `evaluatedConfig` (swancloud `12c02cbb`, guarded by its `srv-holds-no-source` check) until this service changes.

## What Changes

- The host role installs each of its guests from the guest's evaluated configuration, the consuming flake's `nixosConfigurations.<guest>`, and hands microvm.nix no `flake` and no `updateFlake`. A host's closure holds each guest's runner and system and no store path of the flake's source, so a landing that changes none of a host's guests, nor the host itself, releases no host.
- A flake check, `checks.<system>.microvm-host-holds-no-source`, evaluates a host and a guest through the service's roles and the real microvm.nix host module, and fails when the host installs a guest from a flake or when the host's install unit for its guest refers to the flake's source. It first proves its reader on a stand-in host that installs the guest from the flake. `nix flake check`, the merge gate, runs it.
- The microvm README and the microvm gotchas in `services/CLAUDE.md` say how a host installs its guests.
- **BREAKING**: the host no longer writes a `flake` file into `/var/lib/microvms/<guest>/`, so `microvm -u <guest>` on the host can no longer rebuild a guest from a flake. A guest moves only with its host's deploy.

## Capabilities

### New Capabilities

- `microvm-host`: how the microvm host role installs the guests it runs, and what its closure holds of them and of the consuming flake.

### Modified Capabilities

## Impact

- `services/microvm/default.nix`: the host role's `microvm.vms` definitions.
- `flake.nix`: a `checks` output, holding `microvm-host-holds-no-source` for every supported system.
- `tests/microvm-host-holds-no-source.nix`: the check's evaluation, new.
- `services/microvm/README.md`, `services/CLAUDE.md`: documentation.
- Consumers: the lock bump that brings this change alters each host's install units once (the `flake` file goes, a `toplevel` link to the guest's system comes), releasing every host that runs guests one last time. swancloud's srv block that forces `flake = null` and sets `evaluatedConfig` becomes redundant but stays harmless, its `evaluatedConfig` merging with the service's identical one; swancloud removes it in its own change, with that lock bump.
