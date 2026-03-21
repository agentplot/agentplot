## 1. Service Scaffold

- [x] 1.1 Create `services/gno/default.nix` with `_class = "clan.service"`, manifest, and empty server/client roles
- [x] 1.2 Wire `services/gno` into `flake.nix` as `clan.modules.gno`

## 2. Server Role

- [x] 2.1 Define server interface options: `domain` (str), `port` (int, default 8422), `collections` (attrsOf with path + pattern)
- [x] 2.2 Implement OCI container deployment via `virtualisation.oci-containers` with podman, port mapping, and `/persist/gno` bind mount
- [x] 2.3 Generate gno config from collection interface options and pass to container via environment or config file mount
- [x] 2.4 Configure Caddy virtual host with `caddy-cloudflare` TLS, reverse-proxying to gno's HTTP port
- [x] 2.5 Add tmpfiles rules for `/persist/gno` directory creation
- [x] 2.6 Add firewall rule for TCP port 443
- [x] 2.7 Add borgbackup configuration for `/persist/gno`

## 3. Client Role

- [x] 3.1 Define client interface options: `domain`, `port`, `claude-code.mcp.enabled`, `claude-code.profiles`, `agent-deck.mcp.enabled`
- [x] 3.2 Implement HM module with MCP endpoint URL construction (`https://<domain>/mcp`)
- [x] 3.3 Wire `programs.claude-code.mcpServers.gno` with HTTP URL when `claude-code.mcp.enabled` is true
- [x] 3.4 Wire per-profile MCP configuration via `programs.claude-code.profiles`
- [x] 3.5 Wire `programs.agent-deck.mcps.gno` when `agent-deck.mcp.enabled` is true
- [x] 3.6 Register HM module via `agentplot.hmModules.gno-client` with both `nixosModule` and `darwinModule`

## 4. Verification

- [x] 4.1 Verify flake evaluates cleanly with `nix flake check` or `nix eval`
- [x] 4.2 Verify HM module composition test passes if applicable
