## ADDED Requirements

### Requirement: Each service directory contains a user-focused README
Every directory under `services/` that defines a clanService SHALL contain a `README.md` with: a description of what the service does, a link to the upstream project, an overview of roles (server and client), the client capabilities (which agent targets are available), an example inventory configuration snippet, and a reference of key options.

#### Scenario: Service with both server and client roles
- **WHEN** a service like linkding has both server and client roles
- **THEN** the README SHALL document both roles, server deployment details, and client delegation options

#### Scenario: MCP-only service (no skill, no CLI)
- **WHEN** a service like qmd has only MCP capability
- **THEN** the README SHALL show only MCP-related client options in the example configuration and SHALL NOT reference skill or CLI options

#### Scenario: User browsing the repository
- **WHEN** a user navigates to `services/qmd/` in the repository
- **THEN** they SHALL find a README.md that explains what qmd is and how to add it to their Clan inventory without needing to read the Nix code
