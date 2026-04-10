## 1. Service Module

- [ ] 1.1 Create `services/atomic/default.nix` with `_class = "clan.service"`, manifest, and `roles.server`
- [ ] 1.2 Define interface options: `domain` (required string), `port` (optional, default 8080)
- [ ] 1.3 Add clan vars generator for admin bearer token (`openssl rand -hex 32`)
- [ ] 1.4 Configure OCI container via `virtualisation.oci-containers` with `ghcr.io/kenforthewin/atomic-server:latest` image, `--data-dir /persist/atomic --bind 127.0.0.1 --port 8080`, and `PUBLIC_URL` env var
- [ ] 1.5 Add oneshot systemd service for bearer token provisioning — wait for `/health`, then run `atomic-server token create --name admin` with the generated secret
- [ ] 1.6 Configure Caddy reverse proxy: virtual host on `settings.domain`, TLS via `config.caddy-cloudflare.tls`, proxy to `http://localhost:8080`, dataDir at `/persist/caddy`
- [ ] 1.7 Open TCP ports 443 (HTTPS) in firewall
- [ ] 1.8 Declare borgbackup state: `clan.core.state.atomic.folders = ["/persist/atomic"]`
- [ ] 1.9 Add tmpfiles rules for `/persist/atomic` and `/persist/caddy` directories

## 2. Flake Export

- [ ] 2.1 Add `atomic` to `clan.modules` in `flake.nix`

## 3. Validation

- [ ] 3.1 Run `nix flake check` to verify the module evaluates cleanly
