{ mkClientTooling, ... }:
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
                  "serve"
                  "--data-dir" "/persist/atomic"
                  "--bind" "0.0.0.0"
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
              path = [
                pkgs.curl
                config.virtualisation.podman.package
              ];
              script = ''
                # Wait for Atomic server to be healthy
                for i in $(seq 1 60); do
                  if curl -sf http://localhost:${port}/health > /dev/null 2>&1; then
                    break
                  fi
                  sleep 2
                done

                if ! curl -sf http://localhost:${port}/health > /dev/null 2>&1; then
                  echo "Atomic server failed to become healthy after 120s" >&2
                  exit 1
                fi

                TOKEN=$(cat ${tokenPath})
                # Create admin token via CLI inside the container (idempotent)
                podman exec atomic atomic-server token create --name admin --token "$TOKEN" || true
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
              "d /persist/atomic 0750 999 999"
              "d /persist/caddy 0700 caddy caddy"
            ];
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "atomic";
        capabilities = {
          secret = [
            {
              name = "admin-token";
              mode = "shared";
              generator = "atomic-admin-token";
              file = "token";
            }
          ];
          mcp = {
            type = "http";
            urlTemplate = client: "https://${client.domain}/mcp";
            extraConfig = client: {
              tokenFile = client.secretPaths."admin-token";
            };
          };
        };
        extraClientOptions = { lib, ... }: {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN of the Atomic server (e.g., atomic.swancloud.net)";
          };
        };
      };
    in
    {
      description = "Atomic agent tooling (MCP endpoint config, HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
