# microvm

Run Clan machines as MicroVM guests on a host using cloud-hypervisor.

## Roles

- **host** — Machine that runs MicroVM guests. Imports the microvm host module, creates persistent storage directories, and wires up journal forwarding.
- **guest** — Machine that runs as a MicroVM guest. Configures cloud-hypervisor with virtiofs shares for nix store, sops secrets, SSH keys, journal, and persistent storage.

## Settings

### Guest

| Setting | Type | Description |
|---------|------|-------------|
| `host` | string | Inventory machine name of the host that runs this guest |
