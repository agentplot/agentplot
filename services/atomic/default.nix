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
                image = "ghcr.io/kenforthewin/atomic:latest";
                ports = [ "${port}:8081" ];
                volumes = [
                  "/persist/atomic:/data"
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

                # Create admin token via CLI inside container; capture output and persist
                EXISTING=$(podman exec atomic atomic-server token list --data-dir /data 2>/dev/null | grep -c "admin" || true)
                if [ "$EXISTING" = "0" ]; then
                  podman exec atomic atomic-server token create --name admin --data-dir /data 2>&1 | tee /persist/atomic/admin-token.txt
                fi
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

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "atomic";
        capabilities = {
          secret = [
            {
              name = "admin-token";
              mode = "prompted";
            }
          ];
        };
        extraClientOptions = { lib, ... }: {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN of the Atomic server (e.g., atomic.swancloud.net)";
          };
          claude-code.mcp.enabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Wire Atomic MCP into Claude Code";
          };
        };
      };

      wrapPerInstance = origPerInstance: args:
        let
          base = origPerInstance args;
          clientSettings = args.settings.clients or { };
        in
        base // {
          hmModule = { config, lib, pkgs, ... }:
            let
              mkAtomicMcp = clientName: client:
                let
                  generatorName = "agentplot-atomic-${clientName}-admin-token";
                  tokenPath = config.clan.core.vars.generators.${generatorName}.files."admin-token".path;
                  wrapper = pkgs.writeShellScript "atomic-mcp" ''
                    TOKEN=$(cat "${tokenPath}")
                    exec ${pkgs.nodejs}/bin/npx -y mcp-remote \
                      "https://${client.domain}/mcp" \
                      --header "Authorization: Bearer $TOKEN"
                  '';
                in
                lib.mkIf (client.claude-code.mcp.enabled or false) {
                  programs.claude-code.mcpServers."atomic" = {
                    command = toString wrapper;
                    args = [ ];
                  };
                };
            in
            lib.mkMerge ([
              (base.hmModule { inherit config lib pkgs; })
            ] ++ (lib.mapAttrsToList mkAtomicMcp clientSettings));
        };
    in
    {
      description = "Atomic agent tooling (MCP endpoint config, HM delegation)";
      interface = tooling.interface;
      perInstance = wrapPerInstance tooling.perInstance;
    };
}
