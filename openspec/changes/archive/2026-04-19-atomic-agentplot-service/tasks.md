## 1. Service Module

- [x] 1.1 Create `services/atomic/default.nix` with `_class = "clan.service"`, manifest, and `roles.server`
- [x] 1.2 Define interface options: `domain` (required string), `port` (optional, default 8080)
- [x] 1.3 Add clan vars generator for admin bearer token (`openssl rand -hex 32`)
- [x] 1.4 Configure OCI container via `virtualisation.oci-containers` with `ghcr.io/kenforthewin/atomic:latest` (all-in-one image), bind-mount `/persist/atomic:/data`, publish `${settings.port}:8081`, and set `PUBLIC_URL` env var
- [x] 1.5 Add oneshot systemd service for bearer token provisioning — poll `/health`, then run `podman exec atomic atomic-server token create --name admin --data-dir /data` (idempotent via `token list` check)
- [x] 1.6 Configure Caddy reverse proxy: virtual host on `settings.domain`, TLS via `config.caddy-cloudflare.tls`, proxy to `http://localhost:8080`, dataDir at `/persist/caddy`
- [x] 1.7 Open TCP ports 443 (HTTPS) in firewall
- [x] 1.8 Declare borgbackup state: `clan.core.state.atomic.folders = ["/persist/atomic"]`
- [x] 1.9 Add tmpfiles rules for `/persist/atomic` and `/persist/caddy` directories

## 2. Client Role

- [x] 2.1 Add `roles.client` built on `mkClientTooling` with `serviceName = "atomic"`, prompted `admin-token` secret, and `domain` + `claude-code.mcp.enabled` extra options
- [x] 2.2 Wrap `perInstance` with an overlay that emits a stdio MCP wrapper (`npx -y mcp-remote https://<domain>/mcp --header "Authorization: Bearer <token>"`) and registers it under `programs.claude-code.mcpServers.atomic` via `agentplot.hmModules`

## 3. Flake Export

- [x] 3.1 Add `atomic` to `clan.modules` in `flake.nix`

## 4. Validation

- [x] 4.1 Run `nix flake check` to verify the module evaluates cleanly
