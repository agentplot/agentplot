## REMOVED Requirements

### Requirement: OCI container deployment
**Reason**: Replaced by native bun2nix package from llm-agents.nix. No need for Podman/OCI runtime.
**Migration**: Replace `virtualisation.oci-containers.containers.gno` with `systemd.services.gno` using `pkgs.llm-agents.gno`.

### Requirement: Collection bind-mounts
**Reason**: Container bind-mounts are no longer needed. The gno process runs natively and accesses collection paths directly on the filesystem.
**Migration**: Collection paths are passed directly to gno's configuration. For microvm guests, collection directories are available via virtiofs shares or local `/persist` paths.

### Requirement: Gno configuration generation
**Reason**: The OCI-specific config file mounting approach is replaced by direct CLI arguments or environment-based configuration for the native binary.
**Migration**: Configuration is passed via CLI arguments or a config file written to the filesystem (no container mount needed).

## ADDED Requirements

### Requirement: Systemd service with bun2nix package
The server role SHALL deploy gno as a systemd service using `pkgs.llm-agents.gno` from the llm-agents.nix overlay. The service SHALL run gno in MCP HTTP mode on the configured port.

#### Scenario: Service starts with native package
- **WHEN** the NixOS system activates with the gno server role configured
- **THEN** a `gno` systemd service SHALL start using the bun2nix-built gno binary from `pkgs.llm-agents.gno`

#### Scenario: Service runs as dedicated user
- **WHEN** the gno service is running
- **THEN** it SHALL run as a dedicated system user with access to `/persist/gno` for data storage

#### Scenario: Service restarts on failure
- **WHEN** the gno process exits unexpectedly
- **THEN** systemd SHALL restart the service automatically

### Requirement: Collection path access
The server role SHALL pass collection paths directly to gno's configuration. Collection directories SHALL be accessible on the guest filesystem (via virtiofs shares for microvm guests or local paths).

#### Scenario: Collections accessible without container mounts
- **WHEN** collections are configured with host paths
- **THEN** gno SHALL access those paths directly on the filesystem without container volume mounts

### Requirement: Native configuration generation
The server role SHALL generate a gno configuration file from the Nix interface options and write it to the filesystem. The config SHALL specify collections, port, and data directory.

#### Scenario: Config file written to filesystem
- **WHEN** collections and port are configured in Nix
- **THEN** a gno config file SHALL be generated and placed at a path accessible to the gno systemd service
