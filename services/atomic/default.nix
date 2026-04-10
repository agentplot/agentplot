{ ... }:
{
  _class = "clan.service";
  manifest.name = "atomic";
  manifest.description = "Atomic personal knowledge base with semantic search, wiki synthesis, and RAG chat";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "Atomic server (OCI container + Caddy, SQLite-backed)";

    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the Atomic instance (e.g., atomic.swancloud.net)";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8080;
            description = "Internal HTTP port for the Atomic server";
          };
        };
      };

    perInstance =
      {
        settings,
        ...
      }:
      {
        nixosModule =
          {
            config,
            pkgs,
            ...
          }:
          let
            tokenPath = config.clan.core.vars.generators."atomic-admin-token".files."token".path;
            tlsConfig = config.caddy-cloudflare.tls;
            port = toString settings.port;
          in
          {
            # ── Vars generators ──────────────────────────────────────────────

            clan.core.vars.generators."atomic-admin-token" = {
              share = true;
              files."token" = {
                secret = true;
                mode = "0440";
              };
              runtimeInputs = [ pkgs.openssl ];
              script = ''
                openssl rand -hex 32 > $out/token
              '';
            };

            # ── OCI container ────────────────────────────────────────────────

            virtualisation.oci-containers = {
              backend = "podman";
              containers.atomic = {
                image = "ghcr.io/kenforthewin/atomic-server:latest";
                ports = [ "${port}:${port}" ];
                volumes = [
                  "/persist/atomic:/persist/atomic"
                ];
                cmd = [
                  "--data-dir" "/persist/atomic"
                  "--bind" "127.0.0.1"
                  "--port" port
                ];
                environment = {
                  PUBLIC_URL = "https://${settings.domain}";
                };
              };
            };

            # ── Bearer token provisioning ────────────────────────────────────

            systemd.services.atomic-token-provision = {
              description = "Provision Atomic admin bearer token";
              after = [ "podman-atomic.service" ];
              requires = [ "podman-atomic.service" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              path = [ pkgs.curl ];
              script = ''
                # Wait for Atomic server to be healthy
                for i in $(seq 1 60); do
                  if curl -sf http://localhost:${port}/health > /dev/null 2>&1; then
                    break
                  fi
                  sleep 2
                done

                TOKEN=$(cat ${tokenPath})
                # Create admin token (idempotent — exits 0 if already exists)
                curl -sf -X POST \
                  -H "Content-Type: application/json" \
                  -d "{\"name\": \"admin\", \"token\": \"$TOKEN\"}" \
                  http://localhost:${port}/token/create || true
              '';
            };

            # ── Caddy reverse proxy ──────────────────────────────────────────

            services.caddy = {
              enable = true;
              dataDir = "/persist/caddy";
              virtualHosts."${settings.domain}" = {
                extraConfig = ''
                  ${tlsConfig}
                  reverse_proxy http://localhost:${port}
                '';
              };
            };

            # ── Firewall ─────────────────────────────────────────────────────

            networking.firewall.allowedTCPPorts = [ 443 ];

            # ── Borgbackup state ─────────────────────────────────────────────

            clan.core.state.atomic.folders = [
              "/persist/atomic"
            ];

            # ── Tmpfiles ─────────────────────────────────────────────────────

            systemd.tmpfiles.rules = [
              "d /persist/atomic 0750 root root"
              "d /persist/caddy 0700 caddy caddy"
            ];
          };
      };
  };
}
