{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "subcog";
  manifest.description = "Persistent agent memory with hybrid search, knowledge graph, and namespace-scoped retention";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "subcog memory server (Rust binary + Caddy, external PostgreSQL)";

    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the subcog instance (e.g., subcog.swancloud.net)";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8421;
            description = "HTTP port for the subcog server";
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
            lib,
            ...
          }:
          let
            dbPasswordPath = config.clan.core.vars.generators."subcog-db-password".files."password".path;
            tlsConfig = config.caddy-cloudflare.tls;
            port = toString settings.port;
          in
          {
            clan.core.vars.generators."subcog-db-password" = {
              share = true;
              files."password" = {
                secret = true;
                mode = "0440";
              };
              runtimeInputs = [ pkgs.openssl ];
              script = ''
                openssl rand -hex 32 > $out/password
              '';
            };

            systemd.services.subcog-env = {
              description = "Prepare subcog environment file";
              before = [ "subcog.service" ];
              requiredBy = [ "subcog.service" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              path = [ pkgs.openssl ];
              script = ''
                DB_PASSWORD=$(cat ${dbPasswordPath})
                # Generate a stable JWT secret (persists in env file across restarts)
                if [ -f /run/subcog.jwt ]; then
                  JWT_SECRET=$(cat /run/subcog.jwt)
                else
                  JWT_SECRET=$(openssl rand -hex 32)
                  echo "$JWT_SECRET" > /run/subcog.jwt
                fi
                printf '%s\n' \
                  "SUBCOG_DATABASE_URL=postgresql://subcog:$DB_PASSWORD@10.0.0.1/subcog" \
                  "SUBCOG_PORT=${port}" \
                  "SUBCOG_HOST=127.0.0.1" \
                  "SUBCOG_MCP_JWT_SECRET=$JWT_SECRET" \
                  > /run/subcog.env
              '';
            };

            systemd.services.subcog = {
              description = "subcog persistent memory server";
              after = [
                "network.target"
                "subcog-env.service"
              ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "simple";
                User = "subcog";
                Group = "subcog";
                EnvironmentFile = "/run/subcog.env";
                ExecStart = "${pkgs.llm-agents.subcog}/bin/subcog serve --transport http --port ${port}";
                Restart = "on-failure";
                RestartSec = 5;

                # Hardening
                NoNewPrivileges = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ReadWritePaths = [ "/persist/subcog" ];
              };
            };

            users.users.subcog = {
              isSystemUser = true;
              group = "subcog";
              home = "/persist/subcog";
              createHome = true;
            };
            users.groups.subcog = { };

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

            networking.firewall.allowedTCPPorts = [ 443 ];

            clan.core.state.subcog.folders = [ "/persist/subcog" ];

            systemd.tmpfiles.rules = [
              "d /persist/subcog 0755 subcog subcog"
              "d /persist/caddy 0700 caddy caddy"
            ];
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "subcog";
        capabilities = {
          skills = [ ./skills/cli/SKILL.md ];
          cli = {
            package = ./packages/subcog-cli;
            wrapperName = client: "subcog-${client.name}";
          };
          mcp = {
            type = "http";
            urlTemplate = client: "https://${client.domain}/mcp";
          };
        };
        extraClientOptions = { lib, ... }: {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN of the subcog server (e.g., subcog.swancloud.net)";
          };
          namespace = lib.mkOption {
            type = lib.types.str;
            default = "default";
            description = "Memory namespace for scoping";
          };
        };
      };
    in
    {
      description = "subcog MCP client (HTTP endpoint, CLI, skills, HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
