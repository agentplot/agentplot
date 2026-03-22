{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "miniflux";
  manifest.description = "Miniflux RSS reader with agent tooling";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "Miniflux instance (OCI container + Caddy + PostgreSQL)";

    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the Miniflux instance";
          };
          oidc = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable OIDC authentication via Kanidm";
            };
            issuerDomain = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Kanidm server domain for OIDC endpoint construction";
            };
          };
        };
      };

    perInstance =
      {
        settings,
        machine,
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
            oidcEnabled = settings.oidc.enable;
            oidcCfg = config.agentplot.oidc.clients.miniflux;
            dbPasswordPath = config.clan.core.vars.generators."miniflux-db-password".files."password".path;
            tlsConfig = config.caddy-cloudflare.tls;
          in
          {
            imports = [ ../../modules/oidc.nix ];

            agentplot.oidc.clients.miniflux = lib.mkIf oidcEnabled {
              enable = true;
              provider = "kanidm";
              issuerUrl = settings.oidc.issuerDomain;
              clientId = machine.name;
            };

            clan.core.vars.generators."miniflux-db-password" = {
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

            virtualisation.oci-containers = {
              backend = "podman";
              containers.miniflux = {
                image = "miniflux/miniflux:latest";
                ports = [ "8070:8070" ];
                volumes = [
                  "/persist/miniflux:/data"
                ];
                environment = {
                  PORT = "8070";
                  RUN_MIGRATIONS = "1";
                  CREATE_ADMIN = "1";
                  ADMIN_USERNAME = "admin";
                } // lib.optionalAttrs oidcEnabled {
                  OAUTH2_PROVIDER = "oidc";
                  OAUTH2_REDIRECT_URL = "https://${settings.domain}/oauth2/oidc/callback";
                  OAUTH2_USER_CREATION = "1";
                };
                environmentFiles = [ "/run/miniflux-db.env" ] ++ lib.optionals oidcEnabled [ "/run/miniflux-oidc.env" ];
              };
            };

            systemd.services."podman-miniflux" = {
              preStart = lib.mkBefore (
                ''
                  DB_PASSWORD=$(cat ${dbPasswordPath})
                  printf 'DATABASE_URL=user=miniflux password=%s host=10.0.0.1 port=5432 dbname=miniflux sslmode=disable\n' "$DB_PASSWORD" > /run/miniflux-db.env
                ''
                + lib.optionalString oidcEnabled ''
                  SECRET=$(cat ${config.clan.core.vars.generators."oidc-miniflux".files."client-secret".path})
                  printf '%s\n' \
                    "OAUTH2_OIDC_DISCOVERY_ENDPOINT=https://${oidcCfg.issuerUrl}/oauth2/openid/${oidcCfg.clientId}/.well-known/openid-configuration" \
                    "OAUTH2_CLIENT_ID=${oidcCfg.clientId}" \
                    "OAUTH2_CLIENT_SECRET=$SECRET" \
                    > /run/miniflux-oidc.env
                ''
              );
            };

            services.caddy = {
              enable = true;
              dataDir = "/persist/caddy";
              virtualHosts."${settings.domain}" = {
                extraConfig = ''
                  ${tlsConfig}
                  reverse_proxy http://localhost:8070
                '';
              };
            };

            networking.firewall.allowedTCPPorts = [ 443 ];

            systemd.tmpfiles.rules = [
              "d /persist/miniflux 0755 root root"
              "d /persist/caddy 0700 caddy caddy"
            ];
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "miniflux";
        capabilities = {
          skills = [ ./skills/SKILL.md ];
          cli = {
            package = ./packages/miniflux-cli;
            wrapperName = client: client.name;
            envVars = client: {
              MINIFLUX_API_TOKEN = "$(cat ${client.tokenPath})";
              MINIFLUX_BASE_URL = client.base_url;
            };
          };
          secret = {
            name = "api-token";
            mode = "prompted";
            description = client: "API token for Miniflux client '${client.name}'";
          };
        };
        extraClientOptions = { lib, ... }: {
          base_url = lib.mkOption {
            type = lib.types.str;
            description = "Base URL of the Miniflux instance (e.g., 'https://rss.example.com')";
          };
        };
      };
    in
    {
      description = "Miniflux agent tooling (CLI wrappers, skills, downstream HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
