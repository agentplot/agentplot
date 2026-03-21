## MODIFIED Requirements

### Requirement: qmd systemd service
The server role SHALL deploy a systemd service running qmd in Streamable HTTP mode. The service SHALL use `pkgs.llm-agents.qmd` from the llm-agents.nix overlay (not a dedicated flake input) with `--transport http --port <configured-port>` arguments. The service SHALL run as a dedicated system user.

#### Scenario: Service starts with overlay package
- **WHEN** the NixOS system activates with the qmd server role configured
- **THEN** a `qmd` systemd service SHALL start using `pkgs.llm-agents.qmd` from the llm-agents.nix overlay

#### Scenario: Service restarts on failure
- **WHEN** the qmd process exits unexpectedly
- **THEN** systemd SHALL restart the service automatically

## ADDED Requirements

### Requirement: No dedicated flake input for qmd
The agentplot flake SHALL NOT have a `qmd` flake input. The qmd package SHALL be sourced from the `llm-agents.nix` overlay applied at the consuming machine level.

#### Scenario: qmd flake input removed
- **WHEN** agentplot's `flake.nix` is evaluated
- **THEN** `inputs.qmd` SHALL NOT exist

#### Scenario: Package available via overlay
- **WHEN** the qmd server role references the qmd package
- **THEN** it SHALL use `pkgs.llm-agents.qmd` which is provided by the llm-agents.nix overlay applied by the consuming deployment
