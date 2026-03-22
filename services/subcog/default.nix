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
            jwtSecretPath = config.clan.core.vars.generators."subcog-jwt-secret".files."secret".path;
            tlsConfig = config.caddy-cloudflare.tls;
            port = toString settings.port;
          in
          {
            clan.core.vars.generators."subcog-jwt-secret" = {
              share = true;
              files."secret" = {
                secret = true;
                mode = "0440";
              };
              runtimeInputs = [ pkgs.openssl ];
              script = ''
                openssl rand -hex 32 > $out/secret
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
              script = ''
                JWT_SECRET=$(cat ${jwtSecretPath})
                printf '%s\n' \
                  "SUBCOG_DATABASE_URL=postgresql://subcog@10.0.0.1/subcog" \
                  "SUBCOG_JWT_SECRET=$JWT_SECRET" \
                  "SUBCOG_PORT=${port}" \
                  "SUBCOG_HOST=127.0.0.1" \
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
                ExecStart = "${pkgs.llm-agents.subcog}/bin/subcog";
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

            services.borgbackup.jobs.subcog = {
              paths = [ "/persist/subcog" ];
            };

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
          skills = [ ./skills/SKILL.md ];
          mcp = {
            type = "http";
            urlTemplate = client: "https://${client.domain}/mcp";
          };
          secret = {
            name = "jwt-secret";
            mode = "generated";
            description = client: "JWT secret for subcog client '${client.name}'";
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
      description = "subcog MCP client (HTTP endpoint config, JWT auth, HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
