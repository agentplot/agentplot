## Context

See proposal.md, Why. The facts the approach rests on:

- **The host role.** `services/microvm/default.nix` gives each guest whose `settings.host` names this machine `microvm.vms.<guest> = { flake = self; autostart = true; }`. `self` is the consuming flake (swancloud's, not agentplot's): clan hands it to every machine module as a special argument, and the role's own `imports = [ self.inputs.microvm.nixosModules.host ]` reads it before module arguments exist.
- **microvm.nix's install unit** (the lock's `astro/microvm.nix` at `b2028825`, `nixos-modules/host/default.nix`). For each `microvm.vms.<name>` it reads the guest as `flake.nixosConfigurations.<name>.config` when `flake` is set, else `evaluatedConfig.config`: the same lookup. Its `install-microvm-<name>` script always links `current` to the guest's `microvm.declaredRunner`. With a `flake`, it then writes `echo '${flake}' > flake` (or the `updateFlake` string), which interpolates the flake's store path into the script and so into the host's closure. Without one, it links `toplevel` to the guest's `system.build.toplevel` instead.
- **Restarts.** `restartIfChanged` defaults to `config.config != null`, false for a flake and for an `evaluatedConfig` alike: a host switch restarts no guest, before and after this change.
- **The gate.** sluice gates every merge on `nix flake check`. The flake has no `checks` output; the smoke tests in `tests/` read `<nixpkgs>` and run by hand with `nix-instantiate --eval`, outside the gate.
- **swancloud.** srv's block forces `flake = lib.mkForce null` and sets `evaluatedConfig = self.nixosConfigurations.<guest>` (swancloud `12c02cbb`), and its `srv-holds-no-source` check builds srv's toplevel and reads its references graph for the source (`dfd9845f`).
- **A prototype** (scratch, not part of the change) evaluated the service's host and guest roles as `x86_64-linux` NixOS systems from aarch64-darwin with the real microvm.nix host module in about 20 seconds. The `install-microvm-guest` script's string context held `…-source` (the flake) and the runner with today's role, and only the guest's toplevel and runner with `evaluatedConfig`. Two identical `evaluatedConfig` definitions, the service's and swancloud's, merged without error.

## Goals / Non-Goals

**Goals:**

- A host's install units refer to each guest's runner and system and to no store path of the consuming flake's source.
- The merge gate fails the host role if it ever installs a guest from a flake again, by reading what microvm.nix writes rather than what the role says.

**Non-Goals:**

- A guest's own closure. A consumer that stamps its guests (a configuration revision, say) puts its source there itself; swancloud's `unstamped` check holds its guests to that.
- A consumer's whole host closure. Only the consumer can build its host with its inventory and its inputs; swancloud's `srv-holds-no-source` does that for srv.
- Removing swancloud's interim block. That is swancloud's change, made with the lock bump that brings this one.
- An option for a consumer to go back to flake installs. A consumer that wants one sets `microvm.vms.<guest>.flake` itself.

## Decisions

### 1. The host hands microvm.nix `evaluatedConfig = self.nixosConfigurations.<guest>`

The host role gives each of its guests `{ evaluatedConfig = self.nixosConfigurations.${name}; autostart = true; }` and sets neither `flake` nor `updateFlake`. microvm.nix reads the guest's configuration exactly as it did from the flake, the runner is unchanged, and the install script links the guest's toplevel instead of writing the flake's path. The host's closure then holds its guests' systems and nothing of the source.

Alternatives considered:

- **`updateFlake` with `flake = self`.** The script would write the `updateFlake` string instead of the path, but microvm.nix then runs the install unit only once, when the guest's state directory is missing, so a guest would never move with its host's deploy; and the role would have to know a flakeref only the consumer knows.
- **`config = <module>` (microvm.nix's fully-declarative form).** microvm.nix would evaluate the guest itself, apart from clan's `nixosConfigurations`, losing the modules clan gives each machine; and `restartIfChanged` would default to true, restarting guests on every host switch.

### 2. The guard reads the install unit's string context, by evaluation alone

The check evaluates a host and a guest through the service's own roles and the flake's own microvm.nix input, and reads the string context of each `install-microvm-<guest>` script: the store paths it refers to, which are what the host's closure will hold through it. It fails when that context holds the consuming flake's `outPath`.

Alternatives considered:

- **Asserting only the `microvm.vms` definitions.** It would see what the role hands microvm.nix, not what microvm.nix writes, and would miss a future definition that puts the source in another way. The check asserts the definitions too (decision 3), for a clear message, but the context read is what proves the requirement.
- **Building the host's toplevel and reading its references graph, as swancloud does.** It needs a clan inventory and a Linux builder in the gate; agentplot has neither, and the consumer's own check already does this for its real host.

Reading by evaluation needs no Linux build: the `x86_64-linux` systems are instantiated, never built, so the check runs on the darwin hosts the gate runs on.

### 3. The check's shape

`tests/microvm-host-holds-no-source.nix` is a function `{ self }: pkgs: <derivation>`. `flake.nix` imports it once with its own `self` and gives every supported system `checks.<system>.microvm-host-holds-no-source = check nixpkgs.legacyPackages.${system}`, so the host and guest are evaluated once however many systems are checked. The verdict is reached at evaluation, a failure being a `throw` with its message; the derivation is a `runCommand` that touches `$out`, like swancloud's `unstamped`.

Its parts:

- **The roles.** `svc = import ../services/microvm { inherit lib; }`; the host module is `(svc.roles.host.perInstance { roles.guest.machines = { guest.settings = { host = "host"; ageKeyFile = null; }; elsewhere.settings = { host = "other"; ageKeyFile = null; }; }; machine.name = "host"; }).nixosModule`, and the guest module is `(svc.roles.guest.perInstance { }).nixosModule`.
- **Stubs** for the options clan-core and sops-nix would declare and the roles set: `clan.core.state` (attrs of anything), `clan.core.deployment.requireExplicitUpdate` (bool) and `sops.useSystemdActivation` (bool).
- **The consumer** is `self // { nixosConfigurations.guest = guest; }`, handed to both systems as `specialArgs.self` (a special argument, since the host role's `imports` reads it). Its `outPath` is the agentplot flake's source, which stands for any consumer's.
- **The guest** is `nixpkgs.lib.nixosSystem { system = "x86_64-linux"; specialArgs.self = consumer; modules = [ stubs guestModule { networking.hostName = "guest"; } ]; }`.
- **The host** is the same with `hostModule` and `{ networking.hostName = "host"; system.stateVersion = "25.11"; }`. **The stand-in host** adds `{ microvm.vms.guest = { flake = lib.mkForce consumer; evaluatedConfig = lib.mkForce null; }; }`: it installs the guest from the flake, as the role did.
- **The reader** of a system and a guest name is whether `builtins.getContext` of that system's `systemd.services."install-microvm-<name>".script` has the attribute `builtins.unsafeDiscardStringContext (toString consumer.outPath)`.

It throws, naming the requirement and each guest concerned, in this order:

1. the reader does not find the source in the stand-in host (its reader is blind);
2. any of the host's `microvm.vms` sets `flake` or `updateFlake`;
3. the host's `microvm.vms` names are not exactly `[ "guest" ]` (a guest of this host is missing, or `elsewhere` is installed);
4. for each of the host's guests, its `evaluatedConfig.config.system.build.toplevel.drvPath` is not the consumer's `nixosConfigurations.<guest>`'s;
5. for each of the host's guests, its install script's context lacks the guest's toplevel `drvPath` or its `microvm.declaredRunner`'s;
6. for each of the host's guests, the reader finds the source in its install script.

Steps 4 to 6 iterate over the host's `microvm.vms`, so a guest added to the stubbed inventory later is covered without editing them.

### 4. Documentation lands with the role

The README's Host section says the host installs each guest from its evaluated configuration, so its closure holds the guest's system and none of the flake's source, and that a guest moves with its host's deploy, not `microvm -u`. The microvm gotchas in `services/CLAUDE.md` say why the role never hands microvm.nix `flake = self`, naming the check.

## Risks / Trade-offs

- [A host that installed its guests from the flake keeps a stale `/var/lib/microvms/<guest>/flake` file; microvm.nix does not remove it, and `microvm -u <guest>` would rebuild the guest from that old source] → A guest moves only with its host's deploy, as the README says; an operator who wants the file gone deletes it.
- [The lock bump releases every host that runs guests once, its install units changing] → Expected and one-time; after it a host is released only by a change to one of its guests' systems or to its own configuration.
- [The check holds agentplot's microvm.nix lock, not a consumer's] → A consumer with another microvm.nix rev holds its real host with its own closure check, as swancloud does.
- [A future nixpkgs or microvm.nix bump could need a build at evaluation (import from derivation) or rename the install unit] → Either fails the check loudly at evaluation, never passes it silently.
- [The check adds about 20 seconds of evaluation to each gate run] → Small against the gate's 15-minute timeout; it is evaluated once for every system.

## Migration Plan

1. This change lands on agentplot; nothing deploys from agentplot itself.
2. A consumer bumps its `agentplot` input and deploys each host that runs guests once.
3. swancloud removes srv's interim block in that same bump, its `srv-holds-no-source` check still holding srv.

Rollback: revert the consumer's lock bump; the host installs its guests from the flake again and rewrites each `flake` file.
