# microvm

MicroVM infrastructure for running Clan machines as lightweight virtual machine guests on NixOS hosts using cloud-hypervisor.

**Upstream:** [astro/microvm.nix](https://github.com/astro/microvm.nix)

## Benefits

- Lightweight VM isolation for services without the overhead of full virtual machines
- Deterministic network identifiers (MAC addresses, vsock CIDs, machine IDs) derived from hostname, eliminating manual ID management
- Automatic persistent storage directories and journal forwarding from guests to host
- Virtiofs for efficient host-guest sharing of the nix store, secrets, and state

## Roles

| Role | Description |
|------|-------------|
| host | Configures NixOS to run MicroVM guests with networking and storage |
| guest | Configures a NixOS system to run inside a MicroVM |

### Host

Configures the NixOS host to run MicroVM guests. Handles:

- microvm.nix host module import
- Persistent storage directories per guest
- Journal forwarding from guests
- Deterministic machine IDs, MAC addresses, and vsock CIDs derived from hostname
- TAP network interfaces with bridge connectivity

### Guest

Configures a NixOS system to run inside a MicroVM via cloud-hypervisor. Provides:

- Virtiofs shares for nix store, sops secrets, SSH keys, journal, and persistent storage
- Network configuration via TAP interface
- Persistent state directory

## Example Inventory

```nix
{
  services.microvm.host.hypervisor = {
    roles = [ "host" ];
  };

  services.microvm.guest.worker = {
    roles = [ "guest" ];
    config.host = "hypervisor";
  };
}
```

## Key Options

| Option | Type | Description |
|--------|------|-------------|
| `host` (guest role) | string | Inventory machine name of the host that runs this guest |

## Notes

This service has no client role — microVMs are infrastructure-level and do not expose agent tooling.
