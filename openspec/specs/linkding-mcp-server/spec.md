## ADDED Requirements

### Requirement: MCP subcommand in linkding-cli
The linkding-cli wrapper SHALL intercept the `mcp` argument and launch an MCP stdio server instead of dispatching to restish. The MCP server SHALL expose linkding API operations as MCP tools using the bundled `openapi.json` spec.

#### Scenario: CLI invoked with mcp argument
- **WHEN** linkding-cli is invoked with `mcp` as the first argument
- **THEN** the CLI SHALL launch an MCP server on stdio transport (stdin/stdout JSON-RPC) and SHALL NOT invoke restish

#### Scenario: CLI invoked with non-mcp arguments
- **WHEN** linkding-cli is invoked with any argument other than `mcp`
- **THEN** the CLI SHALL dispatch to restish as before with no behavioral change

### Requirement: MCP server authentication
The MCP server SHALL authenticate to the linkding instance using the same environment variables as the restish CLI: `LINKDING_BASE_URL` for the instance URL and `LINKDING_API_TOKEN` for the API token.

#### Scenario: Environment variables present
- **WHEN** the MCP server starts with `LINKDING_BASE_URL` and `LINKDING_API_TOKEN` set
- **THEN** the server SHALL use these values for all API requests to linkding

#### Scenario: Missing environment variables
- **WHEN** the MCP server starts without `LINKDING_BASE_URL` or `LINKDING_API_TOKEN`
- **THEN** the server SHALL exit with a non-zero status and an error message indicating the missing variable

### Requirement: MCP tool coverage
The MCP server SHALL expose tools covering the core linkding API operations: bookmark CRUD, bookmark search, tag listing, and bundle listing at minimum.

#### Scenario: Bookmark operations available
- **WHEN** an MCP client sends `tools/list`
- **THEN** the response SHALL include tools for creating, reading, updating, deleting, searching, archiving, and unarchiving bookmarks

#### Scenario: Tag operations available
- **WHEN** an MCP client sends `tools/list`
- **THEN** the response SHALL include tools for listing and retrieving tags

### Requirement: MCP server packaged as Nix dependency
The MCP server runtime (Python mcp package or mcp-proxy) SHALL be declared as a `runtimeInputs` dependency in the linkding-cli derivation, ensuring it is available in the wrapper's PATH without system-level installation.

#### Scenario: MCP server binary available in wrapper
- **WHEN** the linkding-cli Nix package is built
- **THEN** the MCP server runtime SHALL be in the wrapper's PATH and invocable from the `mcp` subcommand
