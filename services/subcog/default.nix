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
            tlsConfig = config.caddy-cloudflare.tls;
            port = toString settings.port;
          in
          {
            systemd.services.subcog = {
              description = "subcog persistent memory server";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];

              environment = {
                SUBCOG_DATABASE_URL = "postgresql://subcog@10.0.0.1/subcog";
                SUBCOG_PORT = port;
                SUBCOG_HOST = "127.0.0.1";
              };

              serviceConfig = {
                Type = "simple";
                User = "subcog";
                Group = "subcog";
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
          skills = [ ./skills/SKILL.md ./skills/cli.md ];
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
