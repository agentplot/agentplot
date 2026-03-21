{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "linkding";
  manifest.description = "linkding bookmark manager with agent tooling";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "linkding instance (OCI container + Caddy + PostgreSQL)";

    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the linkding instance";
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
            oidcCfg = config.agentplot.oidc.clients.linkding;
            dbPasswordPath = config.clan.core.vars.generators."linkding-db-password".files."password".path;
            tlsConfig = config.caddy-cloudflare.tls;
          in
          {
            imports = [ ../../modules/oidc.nix ];

            agentplot.oidc.clients.linkding = lib.mkIf oidcEnabled {
              enable = true;
              provider = "kanidm";
              issuerUrl = settings.oidc.issuerDomain;
              clientId = machine.name;
            };

            clan.core.vars.generators."linkding-db-password" = {
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
              containers.linkding = {
                image = "sissbruecker/linkding:latest";
                ports = [ "9090:9090" ];
                volumes = [
                  "/persist/linkding:/etc/linkding/data"
                ];
                environment = {
                  LD_SERVER_PORT = "9090";
                  LD_DB_ENGINE = "postgres";
                  LD_DB_HOST = "10.0.0.1";
                  LD_DB_PORT = "5432";
                  LD_DB_DATABASE = "linkding";
                  LD_DB_USER = "linkding";
                } // lib.optionalAttrs oidcEnabled {
                  LD_ENABLE_OIDC = "True";
                  OIDC_USE_PKCE = "True";
                  LD_CSRF_TRUSTED_ORIGINS = "https://${settings.domain}";
                  OIDC_VERIFY_SSL = "True";
                };
                environmentFiles = [ "/run/linkding-db.env" ] ++ lib.optionals oidcEnabled [ "/run/linkding-oidc.env" ];
              };
            };

            systemd.services."podman-linkding" = {
              preStart = lib.mkBefore (
                ''
                  DB_PASSWORD=$(cat ${dbPasswordPath})
                  printf 'LD_DB_PASSWORD=%s\n' "$DB_PASSWORD" > /run/linkding-db.env
                ''
                + lib.optionalString oidcEnabled ''
                  SECRET=$(cat ${config.clan.core.vars.generators."oidc-linkding".files."client-secret".path})
                  printf '%s\n' \
                    "OIDC_OP_AUTHORIZATION_ENDPOINT=${oidcCfg.endpoints.authorization}" \
                    "OIDC_OP_TOKEN_ENDPOINT=${oidcCfg.endpoints.token}" \
                    "OIDC_OP_USER_ENDPOINT=${oidcCfg.endpoints.userinfo}" \
                    "OIDC_OP_JWKS_ENDPOINT=${oidcCfg.endpoints.jwks}" \
                    "OIDC_RP_CLIENT_ID=${oidcCfg.clientId}" \
                    "OIDC_RP_CLIENT_SECRET=$SECRET" \
                    "OIDC_RP_SIGN_ALGO=${oidcCfg.signAlgorithm}" \
                    > /run/linkding-oidc.env
                ''
              );
            };

            services.caddy = {
              enable = true;
              dataDir = "/persist/caddy";
              virtualHosts."${settings.domain}" = {
                extraConfig = ''
                  ${tlsConfig}
                  reverse_proxy http://localhost:9090
                '';
              };
            };

            networking.firewall.allowedTCPPorts = [ 443 ];

            systemd.tmpfiles.rules = [
              "d /persist/linkding 0755 root root"
              "d /persist/caddy 0700 caddy caddy"
            ];
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "linkding";
        capabilities = {
          skills = [ ./skills/SKILL.md ];
          cli = {
            package = ./packages/linkding-cli;
            wrapperName = client: client.name;
            envVars = client: {
              LINKDING_API_TOKEN = "$(cat ${client.tokenPath})";
              LINKDING_BASE_URL = client.base_url;
            };
          };
          secret = {
            name = "api-token";
            mode = "prompted";
            description = client: "API token for linkding client '${client.name}'";
          };
        };
        extraClientOptions = { lib, ... }: {
          base_url = lib.mkOption {
            type = lib.types.str;
            description = "Base URL of the linkding instance (e.g., 'https://links.example.com')";
          };
          default_tags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Default tags for bookmarks created by this client";
          };
        };
      };
    in
    {
      description = "linkding agent tooling (CLI wrappers, skills, downstream HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
