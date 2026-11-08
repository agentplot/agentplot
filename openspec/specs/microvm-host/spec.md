# microvm-host Specification

## Purpose
The microvm service's host role runs Clan machines as MicroVM guests. This capability covers how the host installs the guests assigned to it, and what the host's closure holds of those guests and of the consuming flake.

## Requirements

### Requirement: A host installs each of its guests from its evaluated configuration

The host role SHALL hand microvm.nix, for each guest whose `host` setting names this machine, that guest's evaluated configuration, the consuming flake's `nixosConfigurations.<guest>`, and SHALL hand it no `flake` and no `updateFlake`. A guest assigned to another host SHALL NOT be installed on this one.

#### Scenario: A guest of this host is installed from its evaluated configuration

- **WHEN** an inventory assigns guest `guest` to host `host` and `host`'s configuration is evaluated
- **THEN** `microvm.vms.guest.evaluatedConfig` is the consuming flake's `nixosConfigurations.guest`
- **AND** `microvm.vms.guest.flake` is null
- **AND** `microvm.vms.guest.updateFlake` is null

#### Scenario: A guest of another host is not installed

- **WHEN** an inventory assigns guest `elsewhere` to host `other` and `host`'s configuration is evaluated
- **THEN** `host`'s `microvm.vms` has no entry `elsewhere`

### Requirement: A host's closure holds its guests' systems and none of the flake's source

The units the host's configuration installs each guest with SHALL refer to that guest's runner and system and SHALL refer to no store path of the consuming flake's source, so that a landing that changes none of a host's guests' systems, nor the host's own configuration, leaves the host's system unchanged.

#### Scenario: The install unit refers to the guest's system

- **WHEN** `host`'s `install-microvm-guest` unit is evaluated
- **THEN** its script refers to `guest`'s system toplevel and to `guest`'s declared runner

#### Scenario: The install unit refers to none of the flake's source

- **WHEN** `host`'s `install-microvm-guest` unit is evaluated
- **THEN** its script refers to no store path of the consuming flake's source
- **AND** the host writes no `flake` file into `guest`'s state directory

### Requirement: The merge gate fails a host that holds the flake's source

The repository's flake check SHALL fail when the host role installs a guest from a flake or with an `updateFlake`, or when a host's install unit for a guest refers to the consuming flake's source, naming each such guest. The check SHALL first show that its reader finds the source in a host that installs its guest from the flake, and SHALL fail when it does not.

#### Scenario: A host role that installs a guest from the flake fails the gate

- **WHEN** the host role hands microvm.nix `flake = self` for a guest and `nix flake check` runs
- **THEN** the check `microvm-host-holds-no-source` fails, naming that guest

#### Scenario: The reader is proven before it is trusted

- **WHEN** the check reads a stand-in host that installs `guest` from the consuming flake
- **THEN** the reader finds the flake's source in that host's `install-microvm-guest` unit
- **AND** the check fails, saying its reader is blind, if the reader does not find it

#### Scenario: A host role that installs guests from their evaluated configurations passes the gate

- **WHEN** the host role installs every guest from its evaluated configuration and `nix flake check` runs
- **THEN** the check `microvm-host-holds-no-source` passes
