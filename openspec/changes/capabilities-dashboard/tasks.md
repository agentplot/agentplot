## 1. Serialization Module

- [x] 1.1 Add `agentplot.serialization` option to `modules/agentplot.nix` that evaluates to a JSON-serializable attrset (or null when user is unset)
- [x] 1.2 Extract `mcpServers` from evaluated `home-manager.users.<user>.programs.claude-code.mcpServers` — preserve type and URL, strip non-serializable fields
- [x] 1.3 Extract `skills` from evaluated `home-manager.users.<user>.programs.agent-skills.sources` as a list of source names
- [x] 1.4 Extract `cliTools` — determine approach for identifying agentplot-contributed packages in `home.packages` (convention, internal tracking option, or name-matching)
- [x] 1.5 Extract `agentDeckMcps` from evaluated `home-manager.users.<user>.programs.agent-deck.mcps`
- [x] 1.6 Extract `profiles` from evaluated `home-manager.users.<user>.programs.claude-code.profiles` including per-profile MCP server lists
- [x] 1.7 Include `machine` (from `config.networking.hostName`) and `user` (from `config.agentplot.user`) identification fields

## 2. Nix Evaluation Tests

- [x] 2.1 Add serialization smoke test: evaluate `config.agentplot.serialization` with mock HM modules and verify expected shape (keys present, types correct)
- [x] 2.2 Add null-user test: verify serialization is null when `agentplot.user` is unset
- [x] 2.3 Add empty-modules test: verify serialization produces empty collections when user is set but no services configured
- [x] 2.4 Add JSON roundtrip test: verify `builtins.toJSON config.agentplot.serialization` succeeds without errors

## 3. Dashboard Builders

- [x] 3.1 Create `packages/capabilities-dashboard/default.nix` — `mkCapabilitiesDashboard` function taking `{ pkgs, capabilitiesSerialization }`, embeds JSON in HTML via `__CAPABILITIES_JSON__` placeholder
- [x] 3.2 Create `packages/capabilities-dashboard/inventory.nix` — `mkCapabilitiesInventory` function producing plain JSON file
- [x] 3.3 Add `lib.mkCapabilitiesDashboard` and `lib.mkCapabilitiesInventory` exports to `flake.nix`
- [x] 3.4 Add inline documentation to lib functions with complete multi-machine assembly example showing NixOS + Darwin collection pattern

## 4. Dashboard Serving Module

- [x] 4.1 Create `modules/dashboards.nix` with `agentplot.dashboards` options: `enable`, `domain`, `sites` (attrset of name → derivation)
- [x] 4.2 Generate Caddy virtual host config with path-based routing (`/<site-name>/`) and `file_server` directive per site
- [x] 4.3 Wire TLS via `config.caddy-cloudflare.tls` from agentplot-kit
- [x] 4.4 Export as `nixosModules.dashboards` and `darwinModules.dashboards` in `flake.nix`
- [x] 4.5 Add enable guard — no Caddy config generated when `agentplot.dashboards.enable` is false (default)

## 5. Dashboard HTML

- [x] 5.1 Create `packages/capabilities-dashboard/dashboard.html` — base structure with dark theme matching fleet dashboard palette
- [x] 5.2 Implement machine card view — grid of cards, each showing machine name, user, and capabilities grouped by type (MCP servers, skills, CLI tools, agent-deck MCPs)
- [x] 5.3 Implement profile display — show Claude Code profiles within each machine card with their MCP server assignments
- [x] 5.4 Implement cross-machine comparison view — matrix or side-by-side layout allowing capability diffing across machines
- [x] 5.5 Add filtering/search — filter by capability type, machine name, or specific capability name
