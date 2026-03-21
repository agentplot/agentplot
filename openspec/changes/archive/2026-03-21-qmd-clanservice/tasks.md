## 1. Flake Input and Service Scaffold

- [x] 1.1 Add qmd flake input to flake.nix pointing to upstream repository
- [x] 1.2 Create services/qmd/default.nix with clanService skeleton (manifest, server role, client role)

## 2. Server Role — Interface

- [x] 2.1 Define server interface options: domain (str), port (port, default 8423), collections (attrsOf with path, pattern, exclude)

## 3. Server Role — NixOS Module

- [x] 3.1 Create systemd service for qmd using upstream package with Streamable HTTP transport args
- [x] 3.2 Generate qmd collection configuration from interface options
- [x] 3.3 Configure Caddy virtual host with caddy-cloudflare TLS reverse-proxying to qmd port
- [x] 3.4 Add persistent data directory via systemd.tmpfiles.rules at /persist/qmd
- [x] 3.5 Add borgbackup paths for qmd data directory
- [x] 3.6 Configure firewall to allow TCP 443

## 4. Client Role — Interface

- [x] 4.1 Define client interface options: domain (str), port (port, default 8423), claude-code.mcp.enabled, claude-code.profiles (attrsOf profileSubmodule), agent-deck.mcp.enabled

## 5. Client Role — HM Module Delegation

- [x] 5.1 Create HM module with Claude Code MCP HTTP endpoint config (url-based, not command-based)
- [x] 5.2 Add per-profile MCP delegation for Claude Code profiles
- [x] 5.3 Add agent-deck MCP HTTP delegation
- [x] 5.4 Wire HM module through agentplot.hmModules.qmd-client
- [x] 5.5 Set both nixosModule and darwinModule to the client module for cross-platform support

## 6. Flake Outputs

- [x] 6.1 Add qmd to clan.modules in flake outputs
- [x] 6.2 Pass qmd input to the service module

## 7. Verification

- [x] 7.1 Run nix flake check to verify flake evaluation
- [x] 7.2 Verify service structure matches linkding clanService pattern
